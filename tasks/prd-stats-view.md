# PRD: Session Statistics View

## Self-Clarification

1. **Problem/Goal:** Users have no visibility into brabble health metrics from Claudio. The daily report shows useful stats (success rate, response times, overflow warnings) but users can only see this via log files. Surfacing these in the UI helps users understand system health at a glance.

2. **Core Functionality:**
   - Display today's statistics (transcriptions, success rate, response times)
   - Show health indicator based on recent error counts
   - Accessible from menu bar dropdown

3. **Scope/Boundaries:**
   - NOT modifying brabble itself
   - NOT adding weather API or other integrations
   - NOT fixing audio buffer issues (that's brabble config)
   - Read-only view of existing log data

4. **Success Criteria:**
   - Stats view shows accurate metrics from today's logs
   - Health indicator reflects actual error rates
   - UI updates when logs change

5. **Constraints:**
   - No database/schema changes (none exist anyway)
   - Keep scope small (2-4 hours)
   - Use existing file watching patterns

---

## Introduction

Add a statistics view to Claudio showing today's system health metrics. Users can see success rate, response times, and error counts at a glance without parsing log files.

## Goals

- Surface brabble health metrics in a user-friendly UI
- Provide quick health indicator (green/yellow/red)
- Help users identify when system has issues

## Tasks

### T-001: Create StatsModel for metrics aggregation
**Description:** Add a model to aggregate log data into displayable statistics.

**Acceptance Criteria:**
- [ ] Create `SessionStats` model with: transcriptionCount, successRate, avgResponseTime, overflowCount, noSpeechCount
- [ ] Parse log files to calculate metrics for current day
- [ ] Quality checks pass

### T-002: Add StatsService to watch and parse logs
**Description:** Service that reads brabble logs and calculates current stats.

**Acceptance Criteria:**
- [ ] Create `StatsService` that watches log files
- [ ] Calculate metrics matching claudio-report.sh logic
- [ ] Update stats when logs change
- [ ] Quality checks pass

### T-003: Add StatsView UI component
**Description:** SwiftUI view showing statistics and health indicator.

**Acceptance Criteria:**
- [ ] Display key metrics: transcriptions, success rate, response time
- [ ] Show health indicator dot (green/yellow/red)
- [ ] Consistent with existing Claudio UI style
- [ ] Quality checks pass
- [ ] Verify in app

### T-004: Integrate StatsView into menu dropdown
**Description:** Add stats section to main menu bar dropdown.

**Acceptance Criteria:**
- [ ] Stats visible in dropdown menu
- [ ] Expandable/collapsible section
- [ ] Updates in real-time as logs change
- [ ] Quality checks pass
- [ ] Verify in app

## Functional Requirements

- FR-1: Parse `brabble.log` for overflow and error counts
- FR-2: Parse `claude-hook.log` for request/response success rates
- FR-3: Calculate average response time from timestamp pairs
- FR-4: Display health indicator: green (>90% success), yellow (70-90%), red (<70%)
- FR-5: Show stats section in menu dropdown with today's metrics

## Non-Goals

- No modifying brabble configuration
- No adding new integrations (weather API, etc.)
- No historical stats (just today)
- No settings/preferences for stats

## Technical Considerations

- Reuse existing `FileWatcherService` patterns
- Log paths: `~/Library/Application Support/brabble/`
- Same parsing logic as claudio-report.sh (grep patterns)

## Success Metrics

- Users can see system health in <2 seconds from menu click
- Stats accuracy matches manual log inspection
- No performance degradation from log watching
