-- ============================================================
-- Thai App Market — Database Migration
-- รันใน Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  name TEXT,
  phone TEXT,
  email TEXT,
  role TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  icon_bg TEXT,
  price INTEGER NOT NULL,
  category TEXT,
  rating DECIMAL(2,1) DEFAULT 0,
  reviews INTEGER DEFAULT 0,
  popular BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CART ITEMS TABLE
CREATE TABLE IF NOT EXISTS cart_items (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  product_id BIGINT REFERENCES products NOT NULL,
  quantity INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- 4. ORDERS TABLE
CREATE TABLE IF NOT EXISTS orders (
  id BIGSERIAL PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL,
  total INTEGER NOT NULL,
  status TEXT DEFAULT 'pending',
  payment_method TEXT,
  customer_name TEXT,
  customer_phone TEXT,
  customer_address TEXT,
  note TEXT,
  items JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users can insert own profile" ON profiles;
CREATE POLICY "users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "users can read own profile" ON profiles;
CREATE POLICY "users can read own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "users can update own profile" ON profiles;
CREATE POLICY "users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- PRODUCTS (everyone can read, only admin can write — for now, anon can read)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products are publicly readable" ON products;
CREATE POLICY "products are publicly readable"
  ON products FOR SELECT
  USING (true);

-- CART ITEMS
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users can manage own cart" ON cart_items;
CREATE POLICY "users can manage own cart"
  ON cart_items FOR ALL
  USING (auth.uid() = user_id);

-- ORDERS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users can insert own orders" ON orders;
CREATE POLICY "users can insert own orders"
  ON orders FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users can read own orders" ON orders;
CREATE POLICY "users can read own orders"
  ON orders FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "admin can update order status" ON orders;
CREATE POLICY "admin can update order status"
  ON orders FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- ADMIN: PRODUCTS MANAGEMENT
-- ============================================================

-- Admin can insert products
DROP POLICY IF EXISTS "admin can insert products" ON products;
CREATE POLICY "admin can insert products"
  ON products FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Admin can update products
DROP POLICY IF EXISTS "admin can update products" ON products;
CREATE POLICY "admin can update products"
  ON products FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Admin can delete products
DROP POLICY IF EXISTS "admin can delete products" ON products;
CREATE POLICY "admin can delete products"
  ON products FOR DELETE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- ============================================================
-- AUTO-CREATE PROFILE ON SIGN UP (Trigger)

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists, then create
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- SEED DATA: Products
-- ============================================================

INSERT INTO products (name, description, icon, icon_bg, price, category, rating, reviews, popular) VALUES
  ('เสียงไทย TTS Pro', 'แปลงข้อความภาษาไทยเป็นเสียงสังเคราะห์คุณภาพสูง เลือกเสียงได้ 50+ เสียง ทั้งชาย หญิง และเด็ก ปรับระดับอารมณ์ได้', '🎙️', 'linear-gradient(135deg, #667eea, #764ba2)', 499, 'tts', 4.8, 234, true),
  ('คลิปโปร AI', 'ตัดต่อวิดีโออัตโนมัติด้วย AI มีเทมเพลตสวยๆ พร้อมใช้ ลากวางง่าย ตัดต่อไว มีเอฟเฟกต์ให้เลือกมากมาย', '🎬', 'linear-gradient(135deg, #f093fb, #f5576c)', 799, 'video', 4.7, 189, true),
  ('VoiceClone AI', 'โคลนเสียงภาษาไทยด้วย AI เพียงอัปโหลดเสียงตัวอย่าง 5 นาที ก็ได้เสียงที่เหมือนจริง ใช้กับ TTS ได้', '🗣️', 'linear-gradient(135deg, #4facfe, #00f2fe)', 1299, 'ai', 4.9, 156, true),
  ('SubThai Maker', 'ทำซับไตเติลอัตโนมัติ รองรับทั้งไทยและอังกฤษ แปลภาษาได้ทันที Export ได้หลายฟอร์แมต', '📝', 'linear-gradient(135deg, #43e97b, #38f9d7)', 299, 'subtitle', 4.6, 312, false),
  ('TikTok Cut Pro', 'สร้างคลิปลงตะกร้า TikTok ได้ใน 5 นาที มีเทมเพลตขายของ พร้อมเพลงและเอฟเฟกต์มาแรง', '🛍️', 'linear-gradient(135deg, #a18cd1, #fbc2eb)', 599, 'tiktok', 4.7, 278, true),
  ('AI Content Studio', 'รวมเครื่องมือ AI ครบวงจร ทั้งเขียนบทความ สร้างรูป ตัดต่อคลิป ทำเสียง ทำซับ ครบในแพลตฟอร์มเดียว', '🤖', 'linear-gradient(135deg, #ffecd2, #fcb69f)', 1999, 'ai', 4.9, 421, false)
ON CONFLICT DO NOTHING;

-- ============================================================
-- VERIFICATION
-- ============================================================
-- ตรวจสอบว่าสร้างสำเร็จ:
-- SELECT * FROM products;
-- SELECT * FROM profiles LIMIT 5;
-- SELECT * FROM orders LIMIT 5;
