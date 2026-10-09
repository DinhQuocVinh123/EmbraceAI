import { createClient } from 'npm:@supabase/supabase-js@2';

import { corsHeaders } from '../_shared/cors.ts';

// Model embedding có sẵn trong Supabase Edge Runtime: gte-small, 384 chiều,
// cùng model mà bộ thử nghiệm tools/ai-lab dùng, nên kết quả tìm giống nhau.
declare const Supabase: {
  ai: {
    Session: new (model: string) => {
      run(
        input: string,
        options: { mean_pool: boolean; normalize: boolean },
      ): Promise<number[]>;
    };
  };
};

const embedder = new Supabase.ai.Session('gte-small');
const slugPattern = /^[a-z0-9][a-z0-9-]{0,79}$/;
const keyPattern = /^[a-z0-9][a-z0-9-]{0,119}$/;
const maxChunksPerCall = 10;

interface ChunkInput {
  key: string;
  heading: string;
  content: string;
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function validChunk(value: unknown): value is ChunkInput {
  const chunk = value as Partial<ChunkInput> | null;
  return typeof chunk?.key === 'string' && keyPattern.test(chunk.key) &&
    typeof chunk.heading === 'string' && chunk.heading.trim() !== '' &&
    chunk.heading.length <= 200 &&
    typeof chunk.content === 'string' && chunk.content.trim() !== '' &&
    chunk.content.length <= 4000;
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json(405, { error: 'Method not allowed' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const authorization = request.headers.get('Authorization');
  if (!supabaseUrl || !serviceRoleKey || !authorization) {
    return json(401, { error: 'Staff sign-in is required' });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const token = authorization.replace(/^Bearer\s+/i, '');
  const { data: authData, error: authError } = await admin.auth.getUser(token);
  if (authError || !authData.user) {
    return json(401, { error: 'Staff sign-in is required' });
  }

  const { data: staff } = await admin
    .from('staff_profiles')
    .select('role, active')
    .eq('user_id', authData.user.id)
    .maybeSingle();
  if (!staff?.active || staff.role !== 'admin') {
    return json(403, { error: 'Only an admin can load AI documents' });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json(400, { error: 'Invalid request body' });
  }
  const document = (body.document ?? {}) as Record<string, unknown>;
  const slug = String(document.slug ?? '');
  const title = String(document.title ?? '').trim();
  const version = String(document.version ?? '').trim();
  const chunks = Array.isArray(body.chunks) ? body.chunks : [];
  if (
    !slugPattern.test(slug) || !title || title.length > 200 ||
    !version || version.length > 40 ||
    chunks.length < 1 || chunks.length > maxChunksPerCall ||
    !chunks.every(validChunk)
  ) {
    return json(400, { error: 'The document or its chunks are invalid' });
  }

  const { data: doc, error: docError } = await admin
    .from('ai_documents')
    .upsert(
      { slug, title, version, updated_at: new Date().toISOString() },
      { onConflict: 'slug' },
    )
    .select('id')
    .single();
  if (docError || !doc) return json(500, { error: 'Could not save the document' });

  // Một lần nạp gồm nhiều lô nhỏ: lô đầu xoá các đoạn cũ của tài liệu, các
  // lô sau chỉ thêm vào. Nhờ vậy đoạn đã bỏ khỏi tài liệu không nằm lại kệ.
  if (body.replace === true) {
    const { error } = await admin
      .from('ai_chunks')
      .delete()
      .eq('document_id', doc.id);
    if (error) return json(500, { error: 'Could not clear the old chunks' });
  }

  const rows = [];
  for (const chunk of chunks as ChunkInput[]) {
    const embedding = await embedder.run(chunk.content, {
      mean_pool: true,
      normalize: true,
    });
    rows.push({
      document_id: doc.id,
      chunk_key: chunk.key,
      heading: chunk.heading.trim(),
      content: chunk.content,
      // Array.from: kết quả có thể là mảng số kiểu typed array.
      embedding: JSON.stringify(Array.from(embedding)),
    });
  }

  const { error: chunkError } = await admin
    .from('ai_chunks')
    .upsert(rows, { onConflict: 'document_id,chunk_key' });
  if (chunkError) return json(500, { error: 'Could not save the chunks' });

  await admin.from('audit_logs').insert({
    actor_user_id: authData.user.id,
    action: 'ai.document_loaded',
    detail: { slug, version, chunks: rows.length, replace: body.replace === true },
  });

  return json(200, { slug, version, chunks: rows.length });
});
