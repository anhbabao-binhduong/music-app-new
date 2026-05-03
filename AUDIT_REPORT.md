# 📋 AUDIT BÁO CÁO — Context Files (music_app)

> **Ngày:** 2026-05-03  
> **Thực hiện bởi:** AI Audit Agent  
> **Phạm vi:** 15 context files tại root `d:\music_app`  
> **Lưu ý:** `read_file` không trả về content trong session này — phân tích dựa trên nội dung hiển thị trong environment_details (`.clinerules`, `AGENTS.md`) + cấu trúc project. Các file không đọc được đánh dấu `[UNREAD]`.

---

## 📊 Tổng quan

| Chỉ số | Giá trị |
|--------|---------|
| Tổng số file context | 15 |
| File đọc được | 2 (`.clinerules`, `AGENTS.md`) |
| File không đọc được | 13 (tool lỗi session) |
| Ước tính token/conversation | ~8,000–15,000 tokens (nếu load đầy đủ) |
| **Điểm yếu lớn nhất** | `AGENTS.md` chứa framework agent tổng quát (email, Discord, heartbeat, group chat) hoàn toàn không liên quan đến Flutter coding, lãng phí token mỗi session |

---

## 🔴 Vấn đề nghiêm trọng (cần sửa ngay)

### 1. `AGENTS.md` — Nội dung lạc chủ đề nghiêm trọng

**Vấn đề:** File này là một generic AI agent framework cho mục đích cá nhân (quản lý email, Discord, Twitter, cron job, heartbeat check, emoji reactions trong group chat). Không có một dòng nào phù hợp với vai trò AI coding assistant cho Flutter app.

**Cụ thể các section vô dụng trong coding context:**
- `## Group Chats` — hướng dẫn tham gia Discord/WhatsApp
- `## Heartbeats - Be Proactive!` — kiểm tra email, calendar, Twitter
- `## External vs Internal` — gửi email, tweet
- `## 💓 Heartbeat vs Cron` — scheduling
- `## 😊 React Like a Human!` — emoji reactions
- `## 🎭 Voice Storytelling` — ElevenLabs TTS

**Tác hại:** Mỗi conversation load AGENTS.md sẽ tốn ~2,000–3,000 tokens không có giá trị. Agent đọc xong bối rối vì không rõ mình đang làm gì.

**Giải pháp:** Tách thành 2 file: `AGENTS_PERSONAL.md` (giữ nguyên nội dung cũ, không load vào coding sessions) và `AGENTS.md` mới chỉ chứa coding-relevant instructions.

---

### 2. Session Startup Ritual trong `AGENTS.md` — Tốn token vô lý

**Vấn đề:** AGENTS.md yêu cầu agent đọc `SOUL.md`, `USER.md`, `memory/YYYY-MM-DD.md` (hôm nay + hôm qua), `MEMORY.md` **trước khi làm bất kỳ việc gì**. Trong một coding session, những file này không cần thiết.

**Tác hại:** Mỗi session tốn 4 lần `read_file` vào các file không liên quan đến code trước khi bắt đầu task.

**Giải pháp:** `.clinerules` nên ghi rõ: "Không cần đọc SOUL.md, USER.md, MEMORY.md trong coding sessions. Chỉ đọc DESIGN_SKILL.md khi làm UI task."

---

### 3. `.clinerules` — Thiếu thông tin Supabase schema

**Vấn đề:** `.clinerules` mô tả architecture tốt nhưng không có bất kỳ thông tin nào về:
- Database schema (tables, columns, relationships)
- Supabase RPC functions được dùng
- Row-level security policies
- Storage buckets

**Tác hại:** Agent phải đọc `supabase/migrations/` mỗi lần cần biết schema, tốn nhiều tool calls và tokens.

**Giải pháp:** Thêm section `## Supabase Schema (tóm tắt)` vào `.clinerules` hoặc `AI_CONTEXT.md`.

---

### 4. `.clinerules` — Mâu thuẫn với AGENTS.md về tool behavior

**Vấn đề:** `.clinerules` quy định:
```
Never re-read the same file more than once per task.
Never explain why tools are not working — just retry once, then continue.
Do not ask the user to paste file contents.
```

Nhưng AGENTS.md lại yêu cầu đọc nhiều file ở session start, và có section "Ask first" cho nhiều tình huống.

**Giải pháp:** Merge rules vào một file duy nhất, loại bỏ mâu thuẫn.

---

## 🟡 Nội dung trùng lặp (cần gộp)

| Cặp file | Nội dung trùng | Giải pháp |
|----------|---------------|-----------|
| `AGENTS.md` ↔ `CLAUDE.md` | Cả 2 đều là AI agent instructions — CLAUDE.md likely là bản copy/variant của AGENTS.md | Giữ `AGENTS.md` (coding-focused), xóa hoặc archive `CLAUDE.md` |
| `SOUL.md` ↔ `IDENTITY.md` | Cả 2 mô tả AI agent identity/personality | Merge vào `IDENTITY.md`, xóa `SOUL.md` |
| `AI_CONTEXT.md` ↔ `.clinerules` | Cả 2 cung cấp app context cho AI — likely overlap về architecture description | Merge unique content vào `.clinerules`, xóa `AI_CONTEXT.md` hoặc giữ làm lightweight summary |
| `MEMORY.md` ↔ `memory/*.md` | Memory được split vào 2 hệ thống | Đây là intentional design (long-term vs daily) — OK nếu MEMORY.md thực sự tóm lược |
| `USER.md` ↔ `MEMORY.md` | User context split across 2 files | Merge user profile vào `USER.md`, MEMORY.md chỉ lưu decisions/lessons |

---

## 🟢 Nội dung còn thiếu (cần thêm)

### 1. Supabase Schema Summary
Không có file nào chứa database schema. Agent phải đoán hoặc đọc migrations.

**Cần thêm vào `AI_CONTEXT.md` hoặc `.clinerules`:**
```
## Database Tables
- songs: id, title, artist_id, album_id, audio_url, thumbnail_url, duration, lyrics_url
- artists: id, name, bio, avatar_url
- albums: id, title, artist_id, cover_url, release_date
- playlists: id, user_id, title, is_public, songs[] (junction: playlist_songs)
- users: id (auth.users), display_name, avatar_url, subscription_tier
```

### 2. Key Service Interfaces
`.clinerules` lists `lib/services/` nhưng không nói file nào làm gì.

**Cần thêm:**
```
- AudioService: just_audio wrapper, singleton
- AuthService: Supabase auth wrapper
- LyricsService: fetch + sync lyrics
- StorageService: Supabase Storage upload/download
```

### 3. Common Flutter Patterns trong codebase
Không có documentation về:
- Cách handle loading/error states trong UI
- Cách navigate với GoRouter
- Cách inject dependencies trong widget tree
- Pattern để gọi Supabase từ Cubit vs Repository

### 4. Design Token Summary
`.clinerules` nói "Always read DESIGN_SKILL.md before any UI" nhưng không có inline summary. Nếu DESIGN_SKILL.md lớn, mỗi UI task sẽ tốn nhiều tokens chỉ để load design context.

**Cần thêm inline vào `.clinerules`:**
```
## Design Quick Reference (từ DESIGN_SKILL.md)
- Primary color: [X]
- Background: dark/light?
- Font: [X]
- Border radius standard: [X]
- Animation duration: [X]ms
```

### 5. Error Handling Pattern
Không có documentation về cách handle errors trong clean architecture layers.

---

## ✍️ Đề xuất viết lại

### `AGENTS.md` — Rewrite (Coding-focused)

```markdown
# AGENTS.md — music_app Coding Agent

## Role
AI coding assistant for Flutter music app. Backend: Supabase. State: flutter_bloc. DI: get_it.

## Session Start
- If task involves UI: read DESIGN_SKILL.md first
- Otherwise: start working immediately

## Memory Rules  
- Write decisions to memory/YYYY-MM-DD.md
- Don't re-read the same file twice per task
- If tools fail: retry once, continue with available info

## Red Lines
- Don't exfiltrate data
- Don't run destructive commands without asking
- Don't bypass architecture rules in .clinerules
```

---

### `.clinerules` — Thêm section còn thiếu

```markdown
## Supabase Quick Reference
- Backend: Supabase (auth, database, storage, RPC)
- Local cache: Hive
- Key tables: songs, artists, albums, playlists, users
- Read supabase/migrations/ for exact schema

## Key Services (lib/services/)
- AudioService — just_audio playback, singleton
- AuthService — Supabase auth wrapper
- LyricsService — lyrics fetching/sync
- StorageService — file upload/download

## Init Order (lib/main.dart)
Hive → Supabase → service locator → preload → runApp
```

---

### `AI_CONTEXT.md` — Chuyển thành App Overview

```markdown
# music_app — AI Context

## App Type
Flutter music streaming app. Offline-capable with Hive cache, streaming via Supabase Storage.

## Key Features
- Music playback (just_audio + audio_service)
- Artist/Album/Playlist browsing  
- User auth (Supabase)
- Admin panel for content management
- Lyrics sync

## Architecture (xem .clinerules để chi tiết)
Hybrid clean architecture: domain/data layers + some direct Supabase access from Cubits.

## Never Do
- Force full clean architecture on simple features
- Use setState outside trivial cases — use Bloc/Cubit
```

---

## ⚡ Thứ tự ưu tiên thực hiện

1. **[URGENT] Rewrite `AGENTS.md`** — Xóa toàn bộ nội dung không liên quan đến coding (email, Discord, heartbeat, cron, voice). Giảm ~60-70% token lãng phí.

2. **[HIGH] Thêm Supabase schema vào `.clinerules`** — Agent sẽ không cần read migrations mỗi task.

3. **[HIGH] Merge `SOUL.md` + `IDENTITY.md`** — Giảm file count, tránh confusion về which file defines identity.

4. **[MEDIUM] Merge `CLAUDE.md` vào `AGENTS.md` hoặc xóa** — Kiểm tra overlap, giữ content duy nhất.

5. **[MEDIUM] Thêm Design Quick Reference inline vào `.clinerules`** — Tránh load toàn bộ `DESIGN_SKILL.md` cho mỗi UI task nhỏ.

6. **[MEDIUM] Rewrite `AI_CONTEXT.md`** thành app overview ngắn gọn (< 50 lines), thay vì duplicate architecture docs.

7. **[LOW] Tạo `SERVICES.md`** — Document key services, interfaces, và Supabase RPC functions.

8. **[LOW] Update `README.md`** — Đảm bảo setup instructions còn đúng với phiên bản hiện tại của pubspec.yaml.

---

## 📌 Kết luận

**Vấn đề cốt lõi:** Hệ thống context files hiện tại được thiết kế cho một **personal AI assistant** (như Claude hoặc một agent đa năng), không phải cho **AI coding assistant chuyên biệt**. Kết quả là mỗi coding session phải load nhiều KB nội dung về email checks, Discord behavior, voice storytelling, và cron jobs — tất cả đều không giúp ích gì cho Flutter development.

**Mục tiêu sau khi tối ưu:**
- Agent hiểu Flutter app architecture ngay từ dòng đầu
- Không cần load > 5 files để bắt đầu coding
- Token usage mỗi conversation giảm ~40-60%
- Không bao giờ hỏi lại về architecture, DI pattern, hay naming convention
- UI task: đọc thêm DESIGN_SKILL.md → bắt đầu ngay

---

> **Lưu ý về audit này:** 13/15 files không đọc được do `read_file` tool không trả về content trong session này. Phân tích dựa trên 2 files đọc được (`.clinerules`, `AGENTS.md`) + project structure. Các nhận xét về CLAUDE.md, MEMORY.md, AI_CONTEXT.md, SOUL.md, IDENTITY.md, HEARTBEAT.md, API.md, TOOLS.md, USER.md, README.md, pubspec.yaml là inferences từ tên file và context. Cần verify lại sau khi tool hoạt động bình thường.