1. Tổng quan kiến trúc dữ liệu

Hãy tưởng tượng database như một hệ thống quản lý cuộc thi cá nhân.

User tham gia

Goal là mục tiêu họ đăng ký

Plan / Tasks là kế hoạch AI tạo

Check-in là bằng chứng họ hoàn thành

Stake / Wallet quản lý tiền đặt cược

Data flow
User
 │
 ▼
Goal
 │
 ▼
Plan
 │
 ▼
Daily Tasks
 │
 ▼
Check-ins
 │
 ▼
Stake / Wallet
2. Users

Lưu thông tin người dùng.

CREATE TABLE users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
3. Goals

Một user có thể có nhiều goal.

CREATE TABLE goals (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  description TEXT,
  target_date DATE,
  stake_per_day INTEGER,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);
Ví dụ
goal	stake
IELTS 7.0	$10
Lose 5kg	$5
4. Plans (AI generated plan)

AI sẽ tạo một kế hoạch cho goal.

CREATE TABLE plans (
  id UUID PRIMARY KEY,
  goal_id UUID REFERENCES goals(id),
  total_days INTEGER,
  generated_by TEXT DEFAULT 'ai',
  created_at TIMESTAMP DEFAULT NOW()
);
5. Tasks (daily tasks)

AI breakdown goal thành tasks.

CREATE TABLE tasks (
  id UUID PRIMARY KEY,
  plan_id UUID REFERENCES plans(id),
  day_number INTEGER,
  title TEXT,
  description TEXT,
  estimated_minutes INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);
Ví dụ
day	task
1	Learn 20 vocab
1	Listening practice
2	Write essay
6. Daily Check-ins

User xác nhận hoàn thành task.

CREATE TABLE checkins (
  id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id),
  user_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'pending',
  proof_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

Status:

pending
approved
rejected

Proof:

image
text
link
7. Streaks

Theo dõi consistency.

CREATE TABLE streaks (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  goal_id UUID REFERENCES goals(id),
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  updated_at TIMESTAMP
);
8. Wallet

Quản lý tiền của user.

CREATE TABLE wallets (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  balance INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
9. Stake Commitments

User cam kết tiền cho goal.

CREATE TABLE stakes (
  id UUID PRIMARY KEY,
  goal_id UUID REFERENCES goals(id),
  user_id UUID REFERENCES users(id),
  amount_per_day INTEGER,
  total_committed INTEGER,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP DEFAULT NOW()
);
10. Stake Transactions

Log tiền thắng/thua.

CREATE TABLE stake_transactions (
  id UUID PRIMARY KEY,
  stake_id UUID REFERENCES stakes(id),
  amount INTEGER,
  type TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

Types:

deposit
reward
penalty
refund
11. Payments

Khi user deposit tiền.

Payment provider có thể là Stripe.

CREATE TABLE payments (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  amount INTEGER,
  currency TEXT DEFAULT 'USD',
  provider TEXT,
  provider_payment_id TEXT,
  status TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
12. Notifications

Push notification tracking.

CREATE TABLE notifications (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT,
  body TEXT,
  type TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

Push service có thể dùng
Firebase Cloud Messaging.

13. AI Logs (optional nhưng rất hữu ích)

Lưu request AI để debug.

CREATE TABLE ai_logs (
  id UUID PRIMARY KEY,
  goal_id UUID REFERENCES goals(id),
  prompt TEXT,
  response TEXT,
  model TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
14. ER Diagram (tóm tắt)
users
 │
 ├── goals
 │     │
 │     └── plans
 │            │
 │            └── tasks
 │                   │
 │                   └── checkins
 │
 ├── wallets
 │
 ├── payments
 │
 └── notifications

goals
 │
 └── stakes
        │
        └── stake_transactions
15. Index cần thiết

Để app chạy nhanh.

CREATE INDEX idx_goals_user ON goals(user_id);
CREATE INDEX idx_tasks_plan ON tasks(plan_id);
CREATE INDEX idx_checkins_task ON checkins(task_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
16. MVP có thể đơn giản hơn

Ban đầu chỉ cần:

users
goals
plans
tasks
checkins
stakes
payments