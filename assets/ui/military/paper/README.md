# First-300-year unit scenes

Levy, spearman and archer each have a separate authored action scene. `military_roster_visuals.gd` resolves these exact types before year 300; later-era mappings and unknown-report behavior remain intact. These are role illustrations, not pictures of the particular named soldiers or a promise that equipment is issued. Actual strength, equipment and training continue to come from military state.

Cards contain the whole scene in a 4:3 frame. The early army summary uses the levy assembly with dark text on paper, preserving complete bodies instead of cropping it into a strip of torsos. No simulation, recruitment, equipment or production rules change.

Native generator images are copied intact. Source filenames and exact prompts are in prompts.json and archer-prompt.json. Runtime imports are capped at 1024 pixels with mipmaps. Other early unit types still require their own aesthetic pass.

Support units: field-repair-v1.png binds to field_repair_company and medical-detachment-v1.png binds to medical_detachment during years 0–299. These depict repair work and casualty carrying, not offensive combat or player repair controls. Exact native generation sources and prompts are in support-prompts.json. The shared roster contains each complete scene; existing discovery, equipment, personnel and report gates remain in force.
