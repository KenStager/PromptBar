# PROJECT REQUIREMENTS: PromptBar
*Version 1.0 - MVP Specification*
*Last Updated: January 2025*

## Executive Summary

PromptBar is a macOS menu bar application that provides lightning-fast storage and retrieval of AI prompts with intelligent organization powered by local Ollama integration. This document defines the complete requirements for the Minimum Viable Product (MVP) release.

### Key Principles
1. **Speed First**: Every interaction optimized for sub-second response
2. **Intelligence Without Complexity**: AI enhancement that feels magical, not technical
3. **Invisible Until Needed**: Lives in menu bar, appears instantly when summoned
4. **Privacy by Design**: All data local, no cloud dependencies

### Platform Requirements
- **macOS Version**: 13.0 (Ventura) or later
- **Architecture**: Universal Binary (Apple Silicon + Intel)
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI 5.0+
- **Dependencies**: Ollama (optional but recommended)

## Target Users

### Primary Persona: "Sarah the Software Engineer"
- **Age**: 28
- **Role**: Senior Full-Stack Developer at a startup
- **AI Usage**: Daily user of GitHub Copilot, ChatGPT, and Claude
- **Pain Points**: 
  - Loses effective debugging prompts in chat history
  - Recreates similar prompts multiple times per week
  - No system for organizing prompts by project or technology
- **Goals**: 
  - Build a personal library of proven prompts
  - Quickly access context-specific prompts while coding
  - Share effective prompts with team members

### Secondary Persona: "Marcus the Content Strategist"
- **Age**: 35
- **Role**: Content Marketing Manager at a SaaS company
- **AI Usage**: Creates blog posts, social media, and email campaigns with AI
- **Pain Points**:
  - Prompts scattered across multiple documents and chat sessions
  - Difficult to maintain brand voice consistency
  - Can't track which prompts produce best results
- **Goals**:
  - Maintain consistent brand voice across AI-generated content
  - Organize prompts by content type and campaign
  - Iterate and improve prompts based on performance

### Tertiary Persona: "Dr. Chen the Researcher"
- **Age**: 42
- **Role**: Research Lead at an AI lab
- **AI Usage**: Complex prompts for data analysis, paper summaries, and hypothesis generation
- **Pain Points**:
  - Prompts are often long and complex with multiple components
  - Needs version control for iterative prompt improvement
  - Collaborates with team members who use different systems
- **Goals**:
  - Track prompt evolution and effectiveness
  - Organize prompts by research project and methodology
  - Export and share prompt collections with colleagues

## MVP Feature Scope

### Core Features (MUST HAVE)

1. **Quick Capture**
   - Global hotkey activation (Cmd+Shift+P)
   - Clipboard detection and auto-populate
   - One-click save from clipboard
   - Manual prompt entry
   - Title generation (automatic or manual)

2. **Intelligent Organization**
   - Automatic categorization via Ollama
   - AI-generated descriptions
   - Smart tagging (3-5 tags per prompt)
   - Manual organization override
   - Favorites/starred prompts

3. **Lightning-Fast Retrieval**
   - Instant search with fuzzy matching
   - Search across content, title, tags, and description
   - Keyboard-only navigation
   - One-click copy to clipboard
   - Recent prompts section

4. **Data Management**
   - Local SQLite storage with FTS5
   - Import/Export (JSON format)
   - Backup system (automatic daily)
   - Data migration support

5. **User Interface**
   - Menu bar dropdown (400x600px)
   - Native macOS design language
   - Keyboard shortcuts throughout
   - Visual feedback for all actions

### Features Excluded from MVP (Post-v1.0)
- Team collaboration/sharing
- Cloud synchronization  
- Prompt variables/templates
- Version history tracking
- Usage analytics
- Browser extension
- API access
- Subscription features
- Multi-language support

## Detailed User Stories

### Epic 1: Quick Capture

#### US-101: Hotkey Activation
**As a** user working in any application  
**I want to** activate PromptBar with a global hotkey  
**So that** I can capture prompts without switching contexts

**Acceptance Criteria:**
- [ ] Default hotkey Cmd+Shift+P opens PromptBar dropdown
- [ ] Hotkey works from any application
- [ ] Customizable in preferences
- [ ] Visual indicator when hotkey is pressed
- [ ] Dropdown appears within 100ms
- [ ] Previous application remains in background

#### US-102: Clipboard Detection
**As a** user who just copied a prompt  
**I want** PromptBar to detect and preview clipboard content  
**So that** I can save it immediately

**Acceptance Criteria:**
- [ ] Clipboard content detected on panel open
- [ ] Preview shows first 200 characters
- [ ] "Save from Clipboard" button prominently displayed
- [ ] Clear indicator if clipboard is empty
- [ ] Markdown formatting preserved
- [ ] Multi-line content handled correctly

#### US-103: One-Click Save
**As a** user with clipboard content  
**I want to** save it with a single click  
**So that** capture is frictionless

**Acceptance Criteria:**
- [ ] Single click saves prompt with auto-generated title
- [ ] Visual confirmation (checkmark animation)
- [ ] Ollama analysis begins in background
- [ ] Panel remains open for additional actions
- [ ] Undo option available for 5 seconds
- [ ] Duplicate detection with warning

#### US-104: Manual Entry
**As a** user  
**I want to** manually enter and edit prompts  
**So that** I can refine them before saving

**Acceptance Criteria:**
- [ ] Text field expands as user types
- [ ] Markdown syntax highlighting
- [ ] Tab key inserts proper indentation
- [ ] Cmd+S saves current content
- [ ] Character count indicator
- [ ] Auto-save draft after 5 seconds of inactivity

### Epic 2: Intelligent Organization

#### US-201: Automatic Analysis
**As a** user saving a prompt  
**I want** Ollama to analyze it automatically  
**So that** it's organized without manual effort

**Acceptance Criteria:**
- [ ] Analysis begins within 500ms of save
- [ ] Non-blocking background process
- [ ] Progress indicator in prompt card
- [ ] Analysis completes within 5 seconds (95th percentile)
- [ ] Graceful handling if Ollama unavailable
- [ ] Results appear seamlessly when ready

#### US-202: Smart Categorization
**As a** user  
**I want** prompts automatically categorized  
**So that** I can browse by category

**Acceptance Criteria:**
- [ ] Categories generated from prompt content
- [ ] Common categories: Development, Writing, Analysis, Design, etc.
- [ ] Maximum one primary category per prompt
- [ ] Categories appear in sidebar
- [ ] Prompt count shown per category
- [ ] "Uncategorized" section for pending analysis

#### US-203: Intelligent Tagging
**As a** user  
**I want** relevant tags automatically generated  
**So that** I can find prompts by topic

**Acceptance Criteria:**
- [ ] 3-5 relevant tags per prompt
- [ ] Domain-specific tags (e.g., "python", "debugging", "async")
- [ ] Tags visible in prompt card
- [ ] Click tag to filter results
- [ ] Add/remove tags manually
- [ ] Tag autocomplete when typing

#### US-204: Manual Override
**As a** power user  
**I want to** manually adjust AI categorization  
**So that** I can correct mistakes

**Acceptance Criteria:**
- [ ] Edit mode accessible via right-click or edit button
- [ ] Change category via dropdown
- [ ] Add/remove tags inline
- [ ] Edit description directly
- [ ] Changes persist over re-analysis
- [ ] Bulk edit mode for multiple prompts

### Epic 3: Lightning-Fast Retrieval

#### US-301: Instant Search
**As a** user opening PromptBar  
**I want** to start searching immediately  
**So that** retrieval is instantaneous

**Acceptance Criteria:**
- [ ] Search field auto-focused on open
- [ ] Results update as user types (no Enter required)
- [ ] <50ms response time for results
- [ ] Fuzzy matching tolerates typos
- [ ] Search highlights matching terms
- [ ] Clear button to reset search

#### US-302: Smart Ranking
**As a** user searching  
**I want** most relevant results first  
**So that** I find what I need quickly

**Acceptance Criteria:**
- [ ] Exact matches appear first
- [ ] Favorites prioritized
- [ ] Frequently used prompts ranked higher
- [ ] Recently used considered
- [ ] Title matches weighted over content
- [ ] Tag matches boost relevance

#### US-303: Keyboard Navigation
**As a** keyboard-focused user  
**I want to** navigate entirely with keyboard  
**So that** I never touch the mouse

**Acceptance Criteria:**
- [ ] Arrow keys navigate results
- [ ] Tab moves between sections
- [ ] Enter copies selected prompt
- [ ] Cmd+Enter copies and closes
- [ ] Escape closes panel
- [ ] Number keys (1-9) for quick selection

#### US-304: Quick Actions
**As a** user selecting a prompt  
**I want** quick actions available  
**So that** I can use prompts efficiently

**Acceptance Criteria:**
- [ ] Copy button always visible
- [ ] Edit action via Cmd+E
- [ ] Delete via Delete key (with confirmation)
- [ ] Favorite toggle via Cmd+D
- [ ] View details via Space bar
- [ ] Share via Cmd+Shift+S (future)

## Screen Specifications

### Menu Bar Icon
- **Design**: Minimalist "P" or prompt icon
- **States**: 
  - Default: Monochrome to match system
  - Active: Slight highlight when dropdown open
  - Notification: Badge for import success/failure
- **Size**: Standard menu bar height (22px)
- **Click behavior**: Toggle dropdown panel

### Main Dropdown Panel
**Dimensions**: 400px width × 600px height  
**Position**: Below menu bar icon, right-aligned  
**Background**: System background with vibrancy

#### Header Section (60px)
```
┌─────────────────────────────────────┐
│ 🔍 Search prompts...          [ESC] │
├─────────────────────────────────────┤
│ [★ Favs] [Recent] [Categories] [+]  │
└─────────────────────────────────────┘
```

#### Content Area (480px)
- **Favorites Section** (collapsible)
  - Maximum 5 favorites shown
  - "See all" link if more exist
  
- **Recent Section** (when not searching)
  - Last 5 used prompts
  - Time-based grouping (Today, Yesterday, This Week)

- **Search Results** (when searching)
  - Prompt cards with title, preview, tags
  - Infinite scroll with virtualization
  - Empty state: "No prompts found"

- **Categories View** (tab selection)
  - Grid layout of category tiles
  - Prompt count per category
  - Click to filter

#### Footer Section (60px)
```
┌─────────────────────────────────────┐
│ 5 prompts │ ⚙️ Preferences │ Import │
└─────────────────────────────────────┘
```

### Prompt Card Component
```
┌─────────────────────────────────────┐
│ Prompt Title                    ★ 📋 │
├─────────────────────────────────────┤
│ First 100 characters of prompt...   │
│ content preview with highlighting   │
├─────────────────────────────────────┤
│ #tag1 #tag2 #tag3 │ Category │ 2d  │
└─────────────────────────────────────┘
```

**Interactions**:
- Single click: Select and preview
- Double click: Copy and close
- Right-click: Context menu
- Hover: Show full title tooltip

### Save Dialog (Modal)
**Triggered by**: Save action or clipboard detection  
**Size**: 350px × 250px

```
┌─────────────────────────────────────┐
│ Save Prompt                      X  │
├─────────────────────────────────────┤
│ Title: [Auto-generated or edit]    │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Prompt preview area...          │ │
│ │ (First 4 lines)                 │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│        [Cancel]  [Save Now]         │
└─────────────────────────────────────┘
```

### Preferences Window
**Access**: Menu bar icon right-click → Preferences  
**Type**: Standard macOS preferences window

**Tabs**:
1. **General**
   - Launch at startup
   - Global hotkey configuration
   - Default save behavior

2. **Ollama**
   - Connection status indicator
   - Model selection (if multiple available)
   - Retry configuration
   - Fallback behavior

3. **Data**
   - Storage location
   - Backup frequency
   - Export/Import options
   - Clear all data

4. **Advanced**
   - Debug logging
   - Performance tuning
   - Reset to defaults

## Navigation Flows

### Primary Flow: Save from Clipboard
```
User copies text → Cmd+Shift+P → 
PromptBar opens with clipboard detected →
Click "Save from Clipboard" →
Background Ollama analysis →
Confirmation animation →
Return to previous app
```

### Search and Copy Flow
```
Cmd+Shift+P → Start typing search →
Results update live → Arrow to select →
Enter to copy → Panel closes →
Paste in target application
```

### Browse by Category Flow
```
Cmd+Shift+P → Click Categories tab →
Click category tile → Filtered results →
Select prompt → Copy action
```

### Manual Save Flow
```
Cmd+Shift+P → Click + button →
Type/paste prompt → Add title →
Cmd+S to save → Ollama analysis →
Prompt appears in recent
```

## Input Validation Rules

### Prompt Title
- **Required**: No (auto-generates if empty)
- **Length**: 1-100 characters
- **Default**: First line of prompt or "Untitled Prompt"
- **Characters**: Any Unicode allowed
- **Uniqueness**: Not enforced

### Prompt Content
- **Required**: Yes
- **Length**: 1-50,000 characters
- **Format**: Plain text with Markdown preservation
- **Validation**: Must contain non-whitespace characters
- **Error**: "Prompt cannot be empty"

### Tags
- **Format**: Alphanumeric + hyphen/underscore
- **Length**: 2-30 characters per tag
- **Count**: Maximum 10 tags per prompt
- **Case**: Lowercase enforced
- **Error**: "Tags must be 2-30 characters, letters/numbers only"

### Search Query
- **Length**: No minimum, 200 character maximum
- **Special characters**: Properly escaped for FTS5
- **Operators**: Support AND, OR, NOT
- **Wildcards**: * supported for prefix matching

### Hotkey Configuration
- **Format**: Modifier + Key combination
- **Required modifiers**: At least Cmd or Ctrl
- **Conflicts**: Check against system hotkeys
- **Error**: "This hotkey is already in use"

## Error Handling Specifications

### Ollama Connection Errors

#### Ollama Not Running
```
Type: Warning
Message: "Ollama is not running. Prompts saved without AI analysis."
Actions: [Start Ollama] [Disable Ollama] [Ignore]
Behavior: Save proceeds, manual categorization available
```

#### Analysis Timeout
```
Type: Info
Message: "AI analysis is taking longer than usual..."
Show after: 5 seconds
Behavior: Continue in background, update when complete
```

#### Analysis Failure
```
Type: Warning  
Message: "Could not analyze prompt. Saved without categories."
Actions: [Retry Analysis] [Categorize Manually] [OK]
Log: Detailed error for debugging
```

### Storage Errors

#### Database Write Failure
```
Type: Error
Message: "Failed to save prompt. Check disk space and permissions."
Actions: [Show Details] [Try Again] [Cancel]
Behavior: Keep prompt in memory, retry available
```

#### Corrupt Database
```
Type: Critical
Message: "Prompt database is corrupted. Restore from backup?"
Actions: [Restore Backup] [Start Fresh] [Quit]
Behavior: Prevent further corruption, offer recovery
```

### Import/Export Errors

#### Invalid File Format
```
Type: Error
Message: "Invalid file format. Please select a PromptBar JSON export."
Actions: [Choose Another File] [Cancel]
Behavior: Detailed format requirements in help
```

#### Import Conflicts
```
Type: Warning
Message: "5 prompts already exist. Replace or skip?"
Actions: [Replace All] [Skip Duplicates] [Review Each]
Behavior: Show comparison dialog if reviewing
```

### System Errors

#### Memory Pressure
```
Type: Warning
Message: "PromptBar is using high memory. Clear cache?"
Actions: [Clear Cache] [Ignore]
Behavior: Clear search index cache, maintain data
```

#### Permission Denied
```
Type: Error
Message: "PromptBar needs accessibility permissions for global hotkeys."
Actions: [Open System Preferences] [Disable Hotkeys] [Quit]
Behavior: Guide through system preferences
```

## Performance Requirements

### Response Time Targets
- **Application launch**: <500ms to menu bar icon
- **Dropdown open**: <100ms from hotkey/click
- **Search results**: <50ms for first results
- **Prompt save**: <200ms including UI feedback
- **Ollama analysis**: <5s for 95th percentile
- **Copy to clipboard**: <10ms
- **Category switch**: <100ms

### Resource Constraints
- **Memory usage**: <50MB baseline, <100MB peak
- **CPU usage**: <5% idle, <25% during search
- **Disk usage**: ~10KB per prompt
- **Network**: Only for Ollama (localhost)
- **Battery impact**: Minimal (Energy Impact: Low)

### Scalability Targets
- **Prompt capacity**: 10,000 prompts without degradation
- **Search performance**: O(log n) with FTS5 index
- **Category limit**: 50 categories
- **Tag limit**: 500 unique tags
- **Concurrent operations**: Thread-safe for all operations

## Accessibility Requirements

### Keyboard Accessibility
- **Full keyboard navigation**: All features accessible without mouse
- **Tab order**: Logical flow through UI elements
- **Focus indicators**: Clear visual focus states
- **Shortcuts documented**: In preferences and help

### VoiceOver Support
- **Labels**: All interactive elements labeled
- **Descriptions**: Meaningful action descriptions
- **Announcements**: State changes announced
- **Navigation**: Proper heading structure

### Visual Accessibility
- **Contrast**: WCAG AAA compliance
- **Text size**: Respects system font size
- **Color**: No information by color alone
- **Motion**: Respects reduce motion preference

### Motor Accessibility
- **Target size**: Minimum 24×24pt click targets
- **Spacing**: 8pt minimum between targets
- **Gestures**: No complex gestures required
- **Timing**: No time-limited interactions

## Technical Constraints

### Platform Dependencies
- **macOS APIs**: 
  - NSStatusItem for menu bar
  - NSPasteboard for clipboard
  - CGEvent for global hotkeys
  - NSUserDefaults for preferences

### Third-Party Dependencies
- **SQLite**: Included with macOS
- **FTS5**: Compile-time option for SQLite
- **Ollama**: Optional runtime dependency

### Security Requirements
- **Sandboxing**: Not required for MVP
- **Code signing**: Required for distribution
- **Notarization**: Required for macOS
- **Entitlements**: 
  - Accessibility (for global hotkeys)
  - User-selected file access (import/export)

### Data Privacy
- **Local storage only**: No network except localhost
- **No analytics**: Zero tracking or metrics
- **No cloud sync**: All data remains on device
- **Encryption**: Optional via macOS FileVault

## Success Metrics

### Performance Metrics
- **Save completion**: 95% <200ms
- **Search latency**: 99% <50ms  
- **Ollama success rate**: >90% when available
- **Crash rate**: <0.1%
- **Memory leaks**: Zero tolerance

### User Success Metrics
- **Time to first save**: <30 seconds
- **Time to retrieve**: <2 seconds
- **Hotkey activation rate**: >80% vs click
- **Search success rate**: >95% find target

### Quality Metrics
- **Categorization accuracy**: >85% user agreement
- **Tag relevance**: >80% kept by users
- **Search relevance**: First 3 results contain target
- **Data integrity**: Zero data loss incidents

## LLM Implementation Notes

### Critical Implementation Details

1. **Menu Bar Positioning**
   - Use NSStatusItem with NSStatusBar.system
   - Variable width based on content
   - Handle screen edge cases

2. **Global Hotkey Registration**
   - Use CGEvent tap or NSEvent.addGlobalMonitorForEvents
   - Handle permissions gracefully
   - Conflict detection before setting

3. **SQLite FTS5 Configuration**
   ```sql
   CREATE VIRTUAL TABLE prompts_fts USING fts5(
     title, content, description, tags,
     tokenize='porter unicode61'
   );
   ```

4. **Ollama Integration**
   - HTTP API at http://localhost:11434
   - Timeout handling critical
   - Queue management for multiple requests

5. **Performance Optimizations**
   - Lazy load prompt content
   - Virtual scrolling for long lists
   - Debounce search input
   - Cache compiled search queries

### Common Implementation Pitfalls

1. **Don't block main thread** during Ollama analysis
2. **Don't store clipboard passwords** - check for sensitive content
3. **Don't lose focus** - restore previous app after copy
4. **Don't ignore timezone** in backup timestamps
5. **Don't cache search results** - data changes frequently

### Testing Priorities

1. **Hotkey registration** across system configurations
2. **Ollama failure modes** and recovery
3. **Large dataset performance** (10k+ prompts)
4. **Clipboard encoding edge cases**
5. **Search query SQL injection** prevention

## Appendix A: Ollama Analysis Response Format

```json
{
  "description": "Helps debug Python async/await issues by analyzing code flow",
  "tags": ["python", "debugging", "async", "concurrency", "troubleshooting"],
  "category": "Development",
  "use_cases": ["Finding race conditions", "Debugging deadlocks", "Async flow analysis"],
  "complexity": "intermediate",
  "related_prompts": ["async-error-handler", "concurrency-analyzer"]
}
```

## Appendix B: Import/Export JSON Schema

```json
{
  "version": "1.0",
  "exported_at": "2024-01-15T10:30:00Z",
  "prompts": [
    {
      "id": "uuid-v4",
      "title": "Prompt Title",
      "content": "Full prompt content...",
      "description": "AI-generated description",
      "category": "Development",
      "tags": ["python", "debugging"],
      "created_at": "2024-01-10T08:00:00Z",
      "modified_at": "2024-01-10T08:00:00Z",
      "used_count": 5,
      "last_used_at": "2024-01-15T09:00:00Z",
      "is_favorite": false
    }
  ]
}
```

## Document Version Control

- **Version**: 1.0
- **Status**: Approved for MVP
- **Last Updated**: January 2025
- **Next Review**: Post-MVP launch
- **Approval**: Project stakeholders

---

*Note for LLM: This document represents the complete functional requirements for PromptBar MVP. When implementing, prioritize speed and simplicity. All interactions should feel instantaneous. Reference this document for acceptance criteria and validation rules.*