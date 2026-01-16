---
name: unwire-design-system
description: Comprehensive SwiftUI design system for Unwire productivity app. Applies Duolingo-inspired dark theme aesthetics with playful animations, bold typography, and signature button styles. Use this skill when creating or modifying any UI component to ensure consistent, engaging, professional design throughout the app.
---

# Unwire Design System

## Design Philosophy

Unwire is a productivity app that should feel **alive, playful, and rewarding** like Duolingo, not corporate or sterile. Every interaction should feel satisfying. The dark theme creates focus, while bright accents and animations provide dopamine hits for accomplishments.

## Typography Hierarchy

### Core Principle
Use **heavy, bold weights** for emphasis. Duolingo doesn't whisper—it celebrates. Avoid medium or regular weights for headers.

- **Page Titles**: `.system(size: 32, weight: .heavy)` - Commanding presence
- **Section Headers**: `.system(size: 24, weight: .bold)` - Clear hierarchy
- **Card Titles**: `.system(size: 18, weight: .bold)` - Scannable
- **Buttons**: `.system(size: 17, weight: .heavy)` - Confident CTAs
- **Body Text**: `.system(size: 17, weight: .regular)` - Readable
- **Captions/Meta**: `.system(size: 13, weight: .medium)` - Subtle but clear

### Anti-patterns
- ❌ Don't use .light or .thin weights anywhere
- ❌ Don't use sizes below 13pt except for legal text
- ❌ Don't mix too many font sizes on one screen (max 4 sizes)

## Color System

### Philosophy
Dark, focused background with **punchy, saturated accents**. Colors should feel digital and modern, not muted or pastel.

### Background Layers
- **Primary Background**: `#1D1F2D` - Rich dark navy, not pure black
- **Elevated Cards**: `#262837` - Subtle lift from background
- **Interactive Surfaces**: `#2E3044` - Pressed/hover states

### Brand Color (Primary Blue)
- **Main Blue**: `#1CB0F6` - Vibrant, digital cyan-blue
- **Dark Blue**: `#0E8AC7` - Button shadow/pressed state
- **Light Blue**: `#4DC3FF` - Highlights, glows

### Accent Palette (High Saturation)
- **Success Green**: `#58CC02` - Task completions, celebrations
- **Warning Orange**: `#FF9600` - Active sessions, timers
- **Error Red**: `#FF4B4B` - Destructive actions, blocks
- **Purple**: `#CE82FF` - Special features, premium
- **Yellow**: `#FFC800` - Streaks, achievements

### Text Colors
- **Primary**: Pure white `#FFFFFF` - Headers, important text
- **Secondary**: `white.opacity(0.7)` - Body text, descriptions
- **Tertiary**: `white.opacity(0.5)` - Placeholders, disabled

### Usage Rules
- Use **brand blue** as the default action color (primary buttons, links)
- Use **success green** only for positive outcomes (completed tasks, unlocked apps)
- Reserve **red** for destructive/blocking actions
- Background should always be dark - never introduce light mode elements

## Component Patterns

### The Signature Duolingo Button

This is THE most important visual element. Every primary button must follow this pattern:

**Visual Structure:**
```
┌─────────────────┐
│   BUTTON TEXT   │ ← Main layer (bright color)
└─────────────────┘
  └─────────────┘   ← Shadow layer (darker, offset down 4pt)
```

**Implementation Principles:**
1. **Shadow is a darker version** of the main color (0.7 opacity), offset 4pt down
2. **Rounded corners**: 16pt radius for friendly feel
3. **Press state**: Scale to 0.98 and shift down 2pt
4. **Text**: Heavy weight, all caps or sentence case
5. **Top highlight**: Subtle white stroke (0.1 opacity) for depth
6. **Padding**: Generous (24pt horizontal, 16pt vertical minimum)

**Color Mapping:**
- Primary actions → Brand blue
- Success/Complete → Success green
- Destructive → Error red
- Start timer/session → Warning orange

**Anti-patterns:**
- ❌ Don't use ghost/outline buttons for primary actions
- ❌ Don't use gradient backgrounds (solid colors only)
- ❌ Don't make buttons too small (min 44pt height)
- ❌ Don't use multiple primary buttons on one screen

### Card Components

**Standard Card:**
- Background: `appCard` (#262837)
- Corner radius: 16pt (friendly, not too round)
- Shadow: `black.opacity(0.3), radius: 8, x: 0, y: 4` (subtle depth)
- Padding: 20pt default
- No borders (shadow provides separation)

**Interactive Card (Tappable):**
- Add subtle press animation: scale to 0.98
- Add haptic feedback on tap
- Slightly brighter on press: `appCard.opacity(1.1)`

**Anti-patterns:**
- ❌ Don't use translucent/blur backgrounds
- ❌ Don't add borders (makes it feel corporate)
- ❌ Don't make cards too small (min 60pt height)

### Task Row Pattern

Tasks should feel rewarding to complete:

**Default State:**
- White/translucent background with subtle gradient stroke
- Checkbox on the right (prominent)
- Task text on left (bold when uncompleted)
- Icon indicators for blocking status

**Completed State:**
- Scale down slightly (0.98)
- Reduce opacity (0.6)
- Checkbox fills with white, shows checkmark
- Animate the checkmark with spring animation

**Interaction:**
- Tap anywhere to toggle (big hit target)
- Spring animation on toggle
- Haptic feedback on completion
- Optional confetti/celebration animation

### Progress Bars

**Style:**
- Height: 8-12pt (chunky, visible)
- Background: `white.opacity(0.2)` (subtle)
- Fill: Bright color (green for completion, blue for progress)
- Corner radius: Full pill shape
- Animate width changes with easeInOut

**Anti-patterns:**
- ❌ Don't use thin progress bars (too subtle)
- ❌ Don't animate too slowly (feels sluggish)

## Animation Principles

### Core Philosophy
Animations should feel **snappy and playful**, not slow and corporate. Think Duolingo celebrations, not iOS Settings transitions.

### Timing Guidelines
- **Quick interactions**: 0.2s (button presses, toggles)
- **State changes**: 0.3s (card appearances, checkmarks)
- **Celebrations**: 0.6-1.5s (completion animations, confetti)
- **Page transitions**: 0.25s (smooth but not slow)

### Spring Animations (Preferred)
Use spring animations for most UI interactions:
- `spring(response: 0.3, dampingFraction: 0.7)` - Default
- `spring(response: 0.4, dampingFraction: 0.6)` - More bounce (celebrations)

### When to Animate

**Always animate:**
- ✅ Task completion (checkmark + optional confetti)
- ✅ Button presses (scale + offset)
- ✅ Session start/end (Lottie animation)
- ✅ Tab switches (smooth transition)
- ✅ Card appearances (fade + slide)
- ✅ Progress bar updates (smooth width)
- ✅ Empty state illustrations (floating/breathing)

**Don't animate:**
- ❌ Text changes (instant is clearer)
- ❌ Errors appearing (instant for urgency)
- ❌ Navigation bar updates

### Lottie Integration

Use Lottie for **high-impact moments** only:
- Task completion celebrations (confetti/checkmark explosion)
- Blocking session start (shield forming)
- All tasks completed (big celebration)
- Empty states (subtle floating icons)
- Loading states (smooth spinners)

**Guidelines:**
- Loop only for loading/empty states
- One-shot for celebrations
- Keep file sizes under 100KB
- Preload critical animations

### Haptic Feedback

Pair animations with haptics:
- **Success**: `.notificationOccurred(.success)` - Task complete, unlock
- **Warning**: `.notificationOccurred(.warning)` - Session start, block apps
- **Light**: `.impactOccurred(.light)` - Button taps, toggles

## Layout Patterns

### Screen Structure
Most screens follow this pattern:
1. **Top area**: Large title (60pt from top safe area)
2. **Content area**: Scrollable cards/list
3. **Bottom spacing**: 100pt for tab bar clearance
4. **Horizontal padding**: 20pt sides (consistent)

### Spacing Scale
Use consistent spacing multiples:
- **4pt** - Tight (within components)
- **8pt** - Default (between related items)
- **12pt** - Comfortable (within cards)
- **16pt** - Separated (between sections)
- **24pt** - Distinct (major sections)
- **32pt** - Large gaps (empty states)

### Z-Index Layers
1. Background
2. Content cards
3. Floating buttons
4. Modals/sheets
5. Toasts/alerts
6. Celebration overlays

## State-Specific Patterns

### Empty States
- Large icon (60pt+) in center
- Title: Heavy weight, encouraging
- Subtitle: Explains action needed
- Primary button: Clear next step
- Optional Lottie animation (subtle, looping)

**Tone**: Friendly and motivating, not cold or technical

### Loading States
- Skeleton screens for known content
- Lottie spinner for unknown duration
- Never use UIKit default spinners
- Show partial content if possible

### Error States
- Red accent, but not aggressive
- Clear explanation (not technical)
- Actionable button to resolve
- Optional retry mechanism

## Special Components

### Tab Bar
- Fixed at bottom
- Large icons (24pt)
- Selected state: Brand blue with slight scale up
- Unselected: `white.opacity(0.6)`
- No labels (icons should be clear)

### Floating Action Button
- Circle shape, 64pt diameter
- White background (stands out on dark)
- Icon in `appBackground` color (for contrast)
- Shadow: `black.opacity(0.3), radius: 12, x: 0, y: 6`
- Fixed position (bottom right, 20pt margins)

### Wizard/Multi-step Flows
- Progress indicator at top (step X of Y)
- Large back button (top left)
- Primary button at bottom (fixed)
- One clear action per step
- Celebrate on completion

## Accessibility

While maintaining aesthetics:
- Minimum font size: 13pt
- Minimum tap target: 44x44pt
- Color contrast: AA minimum
- Support Dynamic Type (scale fonts)
- VoiceOver labels on all interactive elements

## Anti-patterns Summary

**Avoid these at all costs:**
- ❌ Translucent/glassmorphism effects (not Duolingo style)
- ❌ Thin, light fonts (looks generic)
- ❌ Muted, pastel colors (lacks energy)
- ❌ Slow animations >0.5s for UI (except celebrations)
- ❌ Corporate blue (#0066CC style) - use vibrant cyan
- ❌ Borders around everything (adds clutter)
- ❌ Multiple competing CTAs on one screen
- ❌ Generic SF Symbols without customization
- ❌ Pure black backgrounds (use rich dark)

## Implementation Checklist

When creating/modifying any view:
- [ ] Uses heavy/bold fonts for headers
- [ ] Primary buttons have shadow offset down 4pt
- [ ] Colors come from defined palette (no random colors)
- [ ] Cards use 16pt corner radius
- [ ] Animations are 0.2-0.3s with spring curves
- [ ] Haptics on important interactions
- [ ] 20pt horizontal padding
- [ ] Minimum 44pt tap targets
- [ ] Celebrates user accomplishments
- [ ] Feels playful and alive, not corporate

## Inspiration References

When designing, think:
- ✅ Duolingo (playful, bold, rewarding)
- ✅ Headspace (calming but engaging)
- ✅ Notion (clean, functional, modern)
- ✅ Linear (fast, precise animations)

NOT:
- ❌ Apple Settings (too minimal, boring)
- ❌ Banking apps (too corporate, stiff)
- ❌ Generic iOS apps (too bland)

---

**Remember**: Every pixel should reinforce that productivity can be fun, rewarding, and beautiful.
