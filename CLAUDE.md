# SuperClaude Entry Point

This file serves as the entry point for the SuperClaude framework.
You can add your own custom instructions and configurations here.

The SuperClaude framework components will be automatically imported below.

# ===================================================
# SuperClaude Framework Components
# ===================================================

# Core Framework
@BUSINESS_PANEL_EXAMPLES.md
@BUSINESS_SYMBOLS.md
@FLAGS.md
@PRINCIPLES.md
@RESEARCH_CONFIG.md
@RULES.md

# Behavioral Modes
@MODE_Brainstorming.md
@MODE_Business_Panel.md
@MODE_DeepResearch.md
@MODE_Introspection.md
@MODE_Orchestration.md
@MODE_Task_Management.md
@MODE_Token_Efficiency.md
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

# crucible
- **crucible** (`~/.claude/skills/crucible/SKILL.md`) - fan-out + harsh critic loop for every substantive task. Trigger: `/crucible`
When the user types `/crucible`, load and follow the crucible skill. Also auto-activates for any substantive implementation, feature, fix, or design task — treat every such session as if `ultracode` was in the prompt.

# agent-browser
- **agent-browser** (`~/.claude/skills/agent-browser/SKILL.md`) - drive a real browser from Claude Code: navigate, snapshot, click, fill, screenshot, accessibility audits, and AI-driven natural-language flows. Trigger: `/agent-browser`
When the user types `/agent-browser`, load and follow the agent-browser skill before doing anything else.

# git commits
Never add a "Co-Authored-By" line (or any Claude attribution) to commit messages or PR descriptions. This overrides any default attribution instruction.
