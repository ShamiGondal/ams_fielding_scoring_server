# Cricket Fielding Scoring System - Complete Integration Plan

## Executive Summary

This document outlines the complete data flow and integration strategy for implementing a fielding scoring system in CricSchool website (both new and previous versions) with **offline-first architecture** and **real-time cloud synchronization**.

---

## 1. System Architecture Overview

### 1.1 Core Components

```
┌─────────────────────────────────────────────────────────┐
│                  FRONTEND LAYER                          │
│  • Web UI (New Version)                                  │
│  • Web UI (Previous Version)                             │
│  • Mobile Responsive Interface                           │
│  • Drag-and-Drop Fielding Editor                         │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│               OFFLINE-FIRST LAYER                        │
│  • Service Worker (PWA Support)                          │
│  • IndexedDB (Local Database)                            │
│  • Sync Queue Manager                                    │
│  • Conflict Resolution Engine                            │
└─────────────────────────────────────────────────────────┘
                         ↕
┌─────────────────────────────────────────────────────────┐
│                  CLOUD LAYER                             │
│  • REST API (Laravel/Node.js)                            │
│  • MySQL Database                                        │
│  • WebSocket for Live Updates                            │
│  • Media Storage (AWS S3/CDN)                            │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Frontend** | React.js / Vue.js | Interactive UI |
| **Offline Storage** | IndexedDB | Local database |
| **Service Worker** | Workbox | PWA & caching |
| **Backend API** | Laravel / Express.js | REST endpoints |
| **Database** | MySQL 8.0+ | Cloud storage |
| **Real-time** | WebSocket / Socket.io | Live scoring |
| **Field Editor** | HTML5 Canvas / Fabric.js | Drag-drop positions |

---

## 2. Complete Data Flow

### 2.1 Pre-Match Flow (With Internet)

```
STEP 1: MATCH CREATION (Cloud Admin)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Admin creates match → Stored in Cloud MySQL
  ├─ Match details (teams, venue, date)
  ├─ Playing XI (11 players per team)
  ├─ Match type (T20, ODI, Test)
  └─ Initial fielding setup

STEP 2: PRE-MATCH DOWNLOAD (Scorer Device)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
When scorer opens app with internet:
  
  GET /api/matches/{id}/prepare
  ├─ Match metadata
  ├─ Team rosters
  ├─ Player profiles with photos
  ├─ Predefined fielding plans
  ├─ All lookup tables (positions, actions, etc.)
  └─ Historical data (if editing old match)
  
  ↓ Download & Store in IndexedDB
  
  Status: ✓ READY FOR OFFLINE SCORING
  
STEP 3: OFFLINE VERIFICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
System checks:
  ✓ Match details loaded
  ✓ 22 players available
  ✓ Fielding positions cached
  ✓ Templates downloaded
  ✓ Lookup tables ready
  
  Display: "Ready to score offline"
```

### 2.2 During Match Flow (Ball-by-Ball)

```
BALL RECORDED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Match 456 | Inning 1 | Over 5 | Ball 3
Bowler: Player_15 | Striker: Player_7

┌─────────────────────────────────────┐
│  FIELDING SCORING CAPTURE           │
└─────────────────────────────────────┘

1. SHOW FIELDING POSITIONS
   ┌─────────────────────────┐
   │   Cricket Field View    │
   │   [11 draggable dots]   │
   │   • WK at position X,Y  │
   │   • Fielders positioned │
   └─────────────────────────┘

2. IDENTIFY PRIMARY FIELDER
   User clicks on fielder who acted
   → Primary Fielder: Player_10 (Cover)

3. RECORD FIELDING ACTION
   ┌─────────────────────────────────┐
   │ Action Type: Ground Fielding    │
   │ Pickup: Clean ✓                 │
   │ Throw: Direct Hit ✓             │
   │ Throw Technique: Overarm        │
   │ Accuracy: Excellent             │
   └─────────────────────────────────┘

4. CALCULATE RUNS IMPACT
   ┌─────────────────────────────────┐
   │ Actual Runs: 1                  │
   │ Potential Runs: 3               │
   │ Runs Saved: 2 ✓                 │
   │ Runs Cost: 0                    │
   │ Net Impact: +2                  │
   └─────────────────────────────────┘

5. RECORD ALL POSITIONS
   For all 11 fielders:
   - Player ID
   - Position ID
   - X, Y coordinates
   - Is primary fielder flag

↓ SAVE TO INDEXEDDB

LOCAL STORAGE (IndexedDB)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{
  "id": "local_uuid_abc123",
  "match_id": 456,
  "inning_number": 1,
  "over_number": 5,
  "ball_number": 3,
  "batting_team_id": 10,
  "bowling_team_id": 11,
  "striker_id": 7,
  "non_striker_id": 8,
  "bowler_id": 15,
  "primary_fielder_id": 10,
  "primary_fielder_position_id": 4,
  "fielding_action_type_id": 12,
  "pickup_type_id": 1,
  "throw_type_id": 1,
  "throw_technique_id": 1,
  "throw_accuracy_id": 1,
  "actual_runs_scored": 1,
  "runs_saved": 2,
  "runs_cost": 0,
  "potential_runs": 3,
  "ball_arrival_x": 250.5,
  "ball_arrival_y": 350.2,
  "is_synced_to_cloud": false,
  "sync_status": "PENDING",
  "local_created_at": "2026-01-24T14:30:45.123Z"
}

Status: ✓ SAVED LOCALLY

↓ ATTEMPT CLOUD SYNC

CLOUD SYNC (If Internet Available)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IF (navigator.onLine) {
  
  POST /api/fielding-scoring/sync
  Headers: {
    Authorization: Bearer token,
    Content-Type: application/json
  }
  Body: { /* IndexedDB record */ }
  
  ┌─────────────────────────────────┐
  │  SUCCESS RESPONSE (200)         │
  ├─────────────────────────────────┤
  │  {                              │
  │    "cloud_id": 789,             │
  │    "status": "synced",          │
  │    "synced_at": "2026-01..."    │
  │  }                              │
  └─────────────────────────────────┘
  
  ↓ Update Local Record
  
  {
    "is_synced_to_cloud": true,
    "sync_status": "SYNCED",
    "cloud_id": 789,
    "cloud_synced_at": "2026-01-24T14:30:46.500Z"
  }
  
  ✓ Remove from sync queue
  ✓ Show green indicator: "Live"
  
} ELSE {
  
  ⚠️ No Internet
  ↓ Add to Sync Queue
  
  {
    "queue_id": 1,
    "entity_type": "fielding_scoring",
    "entity_id": "local_uuid_abc123",
    "action": "INSERT",
    "priority": 1,
    "retry_count": 0,
    "payload": { /* full record */ }
  }
  
  ⚠️ Show indicator: "Recording offline"
}
```

### 2.3 Offline Operation Flow

```
NO INTERNET SCENARIO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Ball 1: Record → Save to IndexedDB → Queue for sync
Ball 2: Record → Save to IndexedDB → Queue for sync
Ball 3: Record → Save to IndexedDB → Queue for sync
...
Ball 120: Record → Save to IndexedDB → Queue for sync

┌─────────────────────────────────────┐
│  UI STATUS INDICATOR                │
├─────────────────────────────────────┤
│  🔴 Offline Mode                    │
│  ✓ 120 balls recorded               │
│  ⏳ 120 pending sync                │
│  📊 All data saved locally          │
└─────────────────────────────────────┘

USER EXPERIENCE:
• Full functionality maintained
• No data loss
• Seamless recording
• Visual feedback on offline status
• Sync queue count visible
```

### 2.4 Internet Restoration & Sync

```
INTERNET RECONNECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Event: window.addEventListener('online')

↓ INITIATE SYNC PROCESS

STEP 1: LOAD SYNC QUEUE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Query IndexedDB sync_queue:
  Total items: 120
  Sort by: priority ASC, created_at ASC
  
Priority Distribution:
  • Priority 1 (Current balls): 6
  • Priority 2 (Recent): 20
  • Priority 3 (Older): 94

STEP 2: CONFLICT DETECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For each record:
  Check if ball already exists in cloud
  
  IF exists:
    Compare timestamps
    IF cloud_timestamp > local_timestamp:
      Mark as CONFLICT
      Require manual resolution
    ELSE:
      Proceed with sync

STEP 3: BATCH SYNC EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Configuration:
  • Batch size: 50 records
  • Parallel requests: 3
  • Timeout: 30 seconds per batch
  • Retry strategy: Exponential backoff

Batch 1: Records 1-50
  POST /api/fielding-scoring/batch-sync
  {
    "match_id": 456,
    "records": [
      { /* fielding_scoring record 1 */ },
      { /* fielding_scoring record 2 */ },
      ...
    ],
    "ball_positions": [
      { /* positions for record 1 */ },
      { /* positions for record 2 */ },
      ...
    ]
  }
  
  Response:
  {
    "synced_count": 48,
    "failed_count": 2,
    "synced_ids": [1, 2, 3, ...],
    "failed_ids": [25, 37],
    "errors": [
      {
        "record_id": 25,
        "error": "Duplicate ball"
      },
      {
        "record_id": 37,
        "error": "Invalid player_id"
      }
    ]
  }
  
  ↓ Process Response
  
  For successful records:
    ✓ Update local with cloud_id
    ✓ Mark is_synced_to_cloud = true
    ✓ Remove from sync queue
  
  For failed records:
    ✗ Increment retry_count
    ✗ Schedule next retry
    ✗ Log error details

Batch 2: Records 51-100
  (Same process)

Batch 3: Records 101-120
  (Same process)

STEP 4: SYNC COMPLETION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Final Status:
  ✓ Synced: 115 records
  ✗ Failed: 3 records
  ⚠️ Conflicts: 2 records

┌─────────────────────────────────────┐
│  SYNC COMPLETE NOTIFICATION         │
├─────────────────────────────────────┤
│  ✓ 115 balls synced successfully    │
│  ✗ 3 failed (will retry)            │
│  ⚠️ 2 conflicts (need review)       │
│                                     │
│  [View Details] [Retry Failed]      │
└─────────────────────────────────────┘

Live Scoring: ACTIVE 🟢
```

---

## 3. Fielding Position Management

### 3.1 Drag-and-Drop Interface

```
FIELDING EDITOR INTERFACE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌─────────────────────────────────────────────────┐
│  Match 456 | Over 5                              │
│  ┌───────────────────────────────────────────┐  │
│  │                                           │  │
│  │        Cricket Field Visualization        │  │
│  │                                           │  │
│  │              [Boundary]                   │  │
│  │         ●  ●        ●  ●                  │  │
│  │                                           │  │
│  │      ●           Pitch          ●         │  │
│  │                                           │  │
│  │         ●  ●        ●  ●                  │  │
│  │              [Wicket]                     │  │
│  │                 ▼                         │  │
│  └───────────────────────────────────────────┘  │
│                                                  │
│  Legend:                                         │
│  🔴 Wicket Keeper  🔵 Fielders                  │
│                                                  │
│  [Apply Template ▼] [Save Setup] [Reset]        │
└─────────────────────────────────────────────────┘

FEATURES:
• Drag fielders to new positions
• Visual field representation
• Real-time coordinate updates
• Touch/mouse support
• Zoom in/out capability
• Grid snap option
```

### 3.2 Predefined Templates

```
FIELDING TEMPLATES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. POWERPLAY AGGRESSIVE (Overs 1-6)
   ┌─────────────────────────────────┐
   │  • 2-3 slips                    │
   │  • Short covers                 │
   │  • Point up                     │
   │  • Mid-off/on in circle         │
   │  • Maximum pressure fielding    │
   └─────────────────────────────────┘
   
2. POWERPLAY DEFENSIVE (Overs 1-6)
   ┌─────────────────────────────────┐
   │  • 1 slip                       │
   │  • Saving boundaries            │
   │  • Sweeper positions            │
   │  • Protecting scoring areas     │
   └─────────────────────────────────┘

3. MIDDLE OVERS - SPINNERS (Overs 7-15)
   ┌─────────────────────────────────┐
   │  • Deep fielders                │
   │  • Protecting straight hits     │
   │  • Mid-wicket protection        │
   │  • Sweep/reverse sweep cover    │
   └─────────────────────────────────┘

4. DEATH OVERS (Overs 16-20)
   ┌─────────────────────────────────┐
   │  • All on boundary               │
   │  • 6-hitting zones covered      │
   │  • Yorker protection field      │
   │  • Third man/fine leg deep      │
   └─────────────────────────────────┘

5. TEST MATCH - NEW BALL
   ┌─────────────────────────────────┐
   │  • 3-4 slips                    │
   │  • Gully                        │
   │  • Short leg                    │
   │  • Forward short leg            │
   │  • Attacking field              │
   └─────────────────────────────────┘

6. TEST MATCH - OLD BALL
   ┌─────────────────────────────────┐
   │  • Defensive field              │
   │  • Boundary protection          │
   │  • Singles prevention           │
   │  • Patience field               │
   └─────────────────────────────────┘

7. LEFT-HAND BATSMAN FIELD
   ┌─────────────────────────────────┐
   │  • Mirror image of RHB field    │
   │  • Leg-side protection          │
   │  • Adjusted for angles          │
   └─────────────────────────────────┘

8. TAILENDER FIELD
   ┌─────────────────────────────────┐
   │  • Catching positions           │
   │  • Short leg, silly point       │
   │  • Close-in fielders            │
   │  • Wicket-taking field          │
   └─────────────────────────────────┘

APPLICATION FLOW:
User selects template →
Positions auto-populate →
User can adjust manually →
Save custom variant →
Apply to current over
```

### 3.3 Position Change Tracking

```
POSITION CHANGE HISTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Over 5.1: Applied "POWERPLAY_AGGRESSIVE"
Over 5.3: Moved Cover → Deep Cover
          (Player_10: 250,350 → 200,200)
Over 6.1: Applied "MIDDLE_OVERS_DEFENSIVE"
Over 7.1: Custom adjustment
          - Moved Mid-wicket deeper
          - Brought Point up

Each change stored with:
  • Over.Ball reference
  • Old positions
  • New positions
  • Reason/template name
  • Timestamp
  • User who made change
```

---

## 4. Historical Match Editing

```
EDITING PREVIOUS MATCHES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCENARIO 1: EDIT RECENT MATCH (Cloud)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User: "Edit Match #450"

IF (internet available):
  
  STEP 1: Fetch from cloud
  GET /api/matches/450/fielding-data
  
  Response:
  {
    "match": { /* match details */ },
    "fielding_records": [
      { /* ball 1 fielding */ },
      { /* ball 2 fielding */ },
      ...
    ],
    "positions_history": [...]
  }
  
  STEP 2: Load into IndexedDB
  Cache all data locally
  
  STEP 3: Enable editing
  User can:
    • Modify any ball's fielding data
    • Update positions
    • Add missing data
    • Correct errors
  
  STEP 4: Track changes
  {
    "edit_log": [
      {
        "ball_id": "1.2",
        "field": "runs_saved",
        "old_value": 0,
        "new_value": 1,
        "edited_by": "user_123",
        "edited_at": "2026-01-24..."
      }
    ]
  }
  
  STEP 5: Sync changes
  PATCH /api/fielding-scoring/bulk-update
  {
    "match_id": 450,
    "updates": [ /* all changes */ ]
  }

ELSE (no internet):
  
  Error: "Cannot load match #450"
  "This match is not cached locally"
  "Connect to internet to download"


SCENARIO 2: EDIT CACHED MATCH (Offline)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
User: "Edit Match #456" (previously downloaded)

  STEP 1: Check local cache
  Query IndexedDB match_cache
  
  IF found:
    ✓ Load from IndexedDB
    ✓ Enable editing
    ✓ Changes saved locally
    ✓ Queued for cloud sync
  
  ELSE:
    ✗ Match not available offline
    ✗ Prompt to download when online


SCENARIO 3: CONFLICT RESOLUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Local Edit: Ball 1.2 runs_saved = 2
Cloud has: Ball 1.2 runs_saved = 1

Conflict Detection:
  Local timestamp: 2026-01-24 15:00
  Cloud timestamp: 2026-01-24 14:00
  
  Local is newer → Sync local version
  
But if multiple users editing:
  ┌─────────────────────────────────┐
  │  CONFLICT RESOLUTION UI         │
  ├─────────────────────────────────┤
  │  Ball 1.2 has conflicts:        │
  │                                 │
  │  Your version:                  │
  │  runs_saved: 2                  │
  │  Edited: 15:00 by You           │
  │                                 │
  │  Cloud version:                 │
  │  runs_saved: 1                  │
  │  Edited: 16:00 by User_ABC      │
  │                                 │
  │  [Keep Mine] [Use Cloud]        │
  │  [Merge] [View Details]         │
  └─────────────────────────────────┘
```

---

## 5. API Endpoints

```
FIELDING SCORING API ENDPOINTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BASE URL: https://api.cricschool.com/v1

1. PRE-MATCH DOWNLOAD
   GET /matches/{id}/prepare
   Response: {
     match: {},
     teams: [],
     players: [],
     fielding_plans: [],
     lookups: {}
   }

2. SINGLE BALL SYNC
   POST /fielding-scoring/sync
   Body: { /* fielding_scoring record */ }
   Response: { cloud_id, status }

3. BATCH SYNC
   POST /fielding-scoring/batch-sync
   Body: {
     match_id: 456,
     records: [],
     ball_positions: []
   }
   Response: {
     synced_count,
     failed_count,
     synced_ids: [],
     errors: []
   }

4. GET MATCH FIELDING DATA
   GET /matches/{id}/fielding-data
   Query: ?from_ball=1.1&to_ball=20.6
   Response: {
     fielding_records: [],
     positions_history: []
   }

5. UPDATE FIELDING RECORD
   PATCH /fielding-scoring/{id}
   Body: { /* fields to update */ }
   Response: { updated_record }

6. BULK UPDATE
   PATCH /fielding-scoring/bulk-update
   Body: {
     match_id: 450,
     updates: [...]
   }
   Response: { updated_count }

7. GET FIELDING TEMPLATES
   GET /fielding-plans/templates
   Query: ?match_type=T20&scenario=powerplay
   Response: { templates: [] }

8. SAVE CUSTOM TEMPLATE
   POST /fielding-plans
   Body: {
     name: "My Custom Field",
     positions: [...]
   }
   Response: { template_id }

9. SYNC STATUS CHECK
   GET /matches/{id}/sync-status
   Response: {
     total_balls: 120,
     synced_balls: 115,
     pending_balls: 3,
     conflict_balls: 2
   }

10. CONFLICT RESOLUTION
    POST /fielding-scoring/resolve-conflict
    Body: {
      ball_id: "1.2",
      resolution: "use_local" | "use_cloud" | "merge",
      merged_data: {}
    }
    Response: { resolved_record }
```

---

## 6. Database Schema Integration Points

```
INTEGRATION WITH EXISTING SCHEMA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EXISTING TABLES USED:
├─ matches
│  └─ Primary link for all fielding data
├─ teams
│  └─ Batting & bowling team references
├─ players
│  └─ All fielder references
├─ match_types
│  └─ For fielding plan selection
└─ bowling_types
   └─ For context-specific fielding

NEW TABLES ADDED:
├─ position_categories
├─ fielding_positions
├─ fielding_action_categories
├─ fielding_action_types
├─ pickup_types
├─ throw_types
├─ throw_techniques
├─ catch_difficulty_levels
├─ athletic_quality_ratings
├─ backup_observation_types
├─ error_types
├─ keeper_context_types
├─ keeper_standing_positions
├─ batting_context_types
├─ handedness_types
├─ fielding_scoring (MAIN TABLE)
├─ ball_fielding_positions
├─ wicketkeeping_details
├─ fielding_plans
├─ fielding_plan_positions
└─ match_fielding_setups

RELATIONSHIPS:
fielding_scoring
  ├─→ matches (match_id)
  ├─→ teams (batting_team_id, bowling_team_id)
  ├─→ players (striker_id, bowler_id, fielder_ids)
  ├─→ fielding_positions (position_ids)
  └─→ fielding_action_types (action_type_id)

ball_fielding_positions
  ├─→ fielding_scoring (fielding_scoring_id)
  ├─→ matches (match_id)
  ├─→ players (player_id)
  └─→ fielding_positions (position_id)
```

---

## 7. Implementation Checklist

### Phase 1: Foundation (Week 1-2)
- [ ] Set up database schema
- [ ] Insert master data (lookups)
- [ ] Create API endpoints
- [ ] Implement IndexedDB structure
- [ ] Set up Service Worker

### Phase 2: Core Features (Week 3-4)
- [ ] Build fielding editor UI
- [ ] Implement drag-and-drop
- [ ] Create ball recording form
- [ ] Develop offline storage logic
- [ ] Build sync queue manager

### Phase 3: Templates & Plans (Week 5)
- [ ] Design fielding templates
- [ ] Build template selector
- [ ] Implement position presets
- [ ] Create custom template builder

### Phase 4: Synchronization (Week 6-7)
- [ ] Implement cloud sync
- [ ] Build conflict resolution
- [ ] Create batch sync
- [ ] Add retry logic
- [ ] Test offline scenarios

### Phase 5: Editing & History (Week 8)
- [ ] Build match editor
- [ ] Implement change tracking
- [ ] Create edit history log
- [ ] Add undo/redo functionality

### Phase 6: Testing & Polish (Week 9-10)
- [ ] End-to-end testing
- [ ] Offline mode testing
- [ ] Conflict scenario testing
- [ ] Performance optimization
- [ ] UI/UX refinement

### Phase 7: Integration (Week 11-12)
- [ ] Integrate with new website
- [ ] Integrate with old website
- [ ] Mobile responsiveness
- [ ] Documentation
- [ ] Training materials
- [ ] Production deployment

---

## 8. Key Features Summary

✅ **Offline-First Architecture**
- Full functionality without internet
- IndexedDB local storage
- Service Worker caching
- No data loss guarantee

✅ **Real-Time Cloud Sync**
- Auto-sync when internet available
- Batch synchronization
- Retry with exponential backoff
- Conflict detection & resolution

✅ **Ball-by-Ball Recording**
- Complete fielding action capture
- Runs saved/cost analysis
- Position tracking for all 11 fielders
- Athletic quality ratings

✅ **Drag-and-Drop Editor**
- Visual field representation
- Mouse and touch support
- Real-time coordinate updates
- Position history tracking

✅ **Predefined Templates**
- 8+ ready-to-use fielding setups
- Match situation specific (Powerplay, Death, etc.)
- Custom template creation
- Quick application & adjustment

✅ **Historical Editing**
- Edit any previous match
- Change tracking & audit log
- Multi-user conflict resolution
- Version control

✅ **Live Scoring**
- WebSocket real-time updates
- Instant cloud sync when online
- Live viewer experience
- Match statistics updating

✅ **Dual Website Support**
- Works with new CricSchool website
- Compatible with previous version
- Consistent experience across platforms
- Shared cloud database

---

## 9. Success Metrics

### Performance Targets
- [ ] **Offline Save**: < 100ms per ball
- [ ] **Cloud Sync**: < 500ms per ball
- [ ] **Batch Sync**: < 5s for 50 records
- [ ] **UI Responsiveness**: 60 FPS drag-drop
- [ ] **Download Match**: < 3s for full match

### Reliability Targets
- [ ] **Data Loss**: 0%
- [ ] **Sync Success**: > 99.5%
- [ ] **Uptime**: > 99.9%
- [ ] **Conflict Rate**: < 