-- ================================================================
-- Thai App Market — Supabase Database Schema
-- ================================================================

-- ─── 1. ตาราง Profiles (ต่อจาก Auth.users) ─────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- เปิด Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ให้ผู้ใช้เห็นเฉพาะข้อมูลตัวเอง
CREATE POLICY "users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- ให้ผู้ใช้แก้ไขข้อมูลตัวเอง
CREATE POLICY "users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- ให้ผู้ใช้แทรกข้อมูลตัวเอง (ตอนสมัคร)
CREATE POLICY "users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ─── 2. ฟังก์ชันเช็ค Admin ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() 
    AND role = 'admin'
  );
$$;

-- ─── 3. ตาราง Products ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT DEFAULT '📦',
    icon_bg TEXT DEFAULT 'linear-gradient(135deg, #667eea, #764ba2)',
    image_url TEXT DEFAULT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    category TEXT,
    rating DECIMAL(2,1) DEFAULT 0,
    reviews INTEGER DEFAULT 0,
    popular BOOLEAN DEFAULT false,
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- ทุกคนอ่านได้ (รวมไม่ login)
CREATE POLICY "products public read"
    ON public.products FOR SELECT
    USING (true);

-- Admin จัดการสินค้าได้
CREATE POLICY "admin manage products"
    ON public.products FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ─── 4. ตาราง Cart Items ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cart_items (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    product_id BIGINT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    quantity INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- ผู้ใช้เห็นเฉพาะตะกร้าตัวเอง
CREATE POLICY "users own cart items"
    ON public.cart_items FOR ALL
    USING (auth.uid() = user_id);

-- ─── 5. ตาราง Orders ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.orders (
    id BIGSERIAL PRIMARY KEY,
    order_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending',
    payment_method TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    customer_address TEXT,
    note TEXT,
    coupon TEXT DEFAULT NULL,
    items JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- ผู้ใช้เห็นเฉพาะออเดอร์ตัวเอง
CREATE POLICY "users own orders"
    ON public.orders FOR ALL
    USING (auth.uid() = user_id);

-- Admin จัดการออเดอร์ได้
CREATE POLICY "admin manage orders"
    ON public.orders FOR ALL
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- ─── 6. Trigger: สร้าง Profile อัตโนมัติเมื่อสมัคร ────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, phone, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'phone',
    NEW.email,
    'user'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ─── 7. Seed Data: สินค้าตัวอย่าง (6 รายการ) ──────────────────
INSERT INTO public.products (name, description, icon, icon_bg, price, category, rating, reviews, popular)
VALUES
    ('เสียงไทย TTS Pro',
     'แปลงข้อความภาษาไทยเป็นเสียงสังเคราะห์คุณภาพสูง เลือกเสียงได้ 50+ เสียง ทั้งชาย หญิง และเด็ก ปรับระดับอารมณ์ได้',
     '🎙️', 'linear-gradient(135deg, #667eea, #764ba2)',
     499, 'tts', 4.8, 234, true),

    ('คลิปโปร AI',
     'ตัดต่อวิดีโออัตโนมัติด้วย AI มีเทมเพลตสวยๆ พร้อมใช้ ลากวางง่าย ตัดต่อไว มีเอฟเฟกต์ให้เลือกมากมาย',
     '🎬', 'linear-gradient(135deg, #f093fb, #f5576c)',
     799, 'video', 4.7, 189, true),

    ('VoiceClone AI',
     'โคลนเสียงภาษาไทยด้วย AI เพียงอัปโหลดเสียงตัวอย่าง 5 นาที ก็ได้เสียงที่เหมือนจริง ใช้กับ TTS ได้',
     '🗣️', 'linear-gradient(135deg, #4facfe, #00f2fe)',
     1299, 'ai', 4.9, 156, true),

    ('SubThai Maker',
     'ทำซับไตเติลอัตโนมัติ รองรับทั้งไทยและอังกฤษ แปลภาษาได้ทันที Export ได้หลายฟอร์แมต',
     '📝', 'linear-gradient(135deg, #43e97b, #38f9d7)',
     299, 'subtitle', 4.6, 312, false),

    ('TikTok Cut Pro',
     'สร้างคลิปลงตะกร้า TikTok ได้ใน 5 นาที มีเทมเพลตขายของ พร้อมเพลงและเอฟเฟกต์มาแรง',
     '🛍️', 'linear-gradient(135deg, #a18cd1, #fbc2eb)',
     599, 'tiktok', 4.7, 278, true),

    ('AI Content Studio',
     'รวมเครื่องมือ AI ครบวงจร ทั้งเขียนบทความ สร้างรูป ตัดต่อคลิป ทำเสียง ทำซับ ครบในแพลตฟอร์มเดียว',
     '🤖', 'linear-gradient(135deg, #ffecd2, #fcb69f)',
     1999, 'ai', 4.9, 421, false)
ON CONFLICT DO NOTHING;

-- ─── 8. Reviews ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reviews (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, user_id)
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reviews public read" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "reviews insert own" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews manage own" ON public.reviews FOR ALL USING (auth.uid() = user_id);

-- ─── 9. Coupons ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.coupons (
    id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    discount_value DECIMAL(10,2) NOT NULL,
    min_order DECIMAL(10,2) DEFAULT 0,
    max_uses INTEGER DEFAULT NULL,
    used_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ DEFAULT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "coupons public read" ON public.coupons FOR SELECT USING (true);
CREATE POLICY "admin manage coupons" ON public.coupons FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ─── 10. Storage Bucket สำหรับรูปสินค้า ──────────────────────
-- สร้าง Bucket สำหรับรูปสินค้า (public read)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'product-images',
  'product-images',
  true,
  5242880, -- 5MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- ให้ทุกคนอ่านรูปได้
CREATE POLICY "public read product images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

-- ให้ user ที่ login แล้ว (admin) อัปโหลดรูปได้
CREATE POLICY "auth users upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
  );

-- ให้ user ที่ login แล้ว (admin) อัปเดตรูปได้
CREATE POLICY "auth users update product images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
  );

-- ให้ user ที่ login แล้ว (admin) ลบรูปได้
CREATE POLICY "auth users delete product images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images' 
    AND auth.role() = 'authenticated'
  );
