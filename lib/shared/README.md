# shared/

Cross-feature, app-agnostic building blocks that are reused by 2+ features
but do not belong to `core/` (which holds infrastructure-level primitives).

Examples to add as the project grows:
- shared form widgets (validators, input fields)
- value objects used by multiple domains (e.g. `Money`, `Phone`)
- typedefs and shared mixins

Keep this folder small. If something is used by only one feature, it belongs
inside that feature.
