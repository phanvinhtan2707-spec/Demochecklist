-- 1. 
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. User Profiles & Roles
CREATE TYPE user_role AS ENUM ('technician', 'admin');

CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL,
  role user_role DEFAULT 'technician',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Checklist Templates (Dynamic checklist items)
CREATE TABLE checklist_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  section TEXT NOT NULL, -- e.g., 'Tank Nước', 'Phòng Thang Máy', 'Tầng 16'
  item_name TEXT NOT NULL, -- e.g., 'CB Unit 01', 'Đèn Lobby', 'A/C 1'
  input_type TEXT NOT NULL, -- 'enum', 'number', 'boolean'
  options TEXT[], -- e.g., ['On', 'Off', 'Error'] or ['0', '0.25', '0.5', '0.75', '1', 'Error']
  shift TEXT[] DEFAULT ARRAY['Morning', 'Afternoon'],
  display_order INT DEFAULT 0
);

-- 4. Daily Checklist Submissions
CREATE TABLE checklist_submissions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  technician_id UUID REFERENCES profiles(id),
  technician_name TEXT NOT NULL,
  submission_date DATE NOT NULL,
  shift TEXT NOT NULL CHECK (shift IN ('Morning', 'Afternoon')),
  status TEXT DEFAULT 'Completed' CHECK (status IN ('Draft', 'Completed', 'Approved')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(submission_date, shift)
);

-- 5. Individual Inspection Log Entries
CREATE TABLE checklist_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  submission_id UUID REFERENCES checklist_submissions(id) ON DELETE CASCADE,
  item_id UUID REFERENCES checklist_items(id),
  section TEXT NOT NULL,
  item_name TEXT NOT NULL,
  value TEXT NOT NULL, -- e.g., 'On', 'OK', '0.75', 'Error'
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Public profiles read" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own submission" ON checklist_submissions FOR INSERT WITH CHECK (auth.uid() = technician_id);
CREATE POLICY "Users can read submissions" ON checklist_submissions FOR SELECT USING (true);
CREATE POLICY "Users can insert logs" ON checklist_logs FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can read logs" ON checklist_logs FOR SELECT USING (true);
