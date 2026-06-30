// ================================================================
// Vercel Serverless Function — injects Supabase config at runtime
// ================================================================
// Vercel จะ inject SUPABASE_URL และ SUPABASE_ANON_KEY จาก
// Environment Variables ใน Vercel Dashboard → Project → Settings
// ================================================================

export default function handler(req, res) {
    // CORS headers (allow browser to fetch)
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Content-Type', 'application/json');

    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    const supabaseUrl = process.env.SUPABASE_URL || '';
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';

    if (!supabaseUrl || !supabaseAnonKey) {
        res.status(200).json({
            configured: false,
            message: '⚠️ ยังไม่ได้ตั้งค่า SUPABASE_URL และ SUPABASE_ANON_KEY ใน Vercel Environment Variables'
        });
        return;
    }

    res.status(200).json({
        configured: true,
        supabaseUrl,
        supabaseAnonKey
    });
}
