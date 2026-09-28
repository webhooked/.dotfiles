---
name: model-from-reference
description: Build or refine editable 3D models and scenes from photographs, plans and product references, with attention to spatial accuracy, construction, materials and realistic rendering.
---

# Model from reference

Reconstruct the subject from evidence. Establish layout and construction before
surface detail, and validate materials before developing artistic lighting.
Preserve accepted decisions as the model evolves.

## 1. Establish scale, layout and uncertainty

- Inspect all available photographs together. Identify shared objects, corners
  and openings across views; avoid judging dimensions from one perspective.
- Record which reference controls layout, construction, furnishing and finish
  when plans, photographs and styled mockups differ. Keep useful crops and source
  links with the project. If an attachment becomes unavailable, retrieve it or
  request it again before claiming a visual match.
- Use measured plans where available. Otherwise derive a provisional layout
  from multiple views and known-size objects or identified products.
- Annotate references with dimensions, alignments, clearances, recesses and
  important construction details.
- Distinguish measured dimensions, product specifications, photographic
  estimates and unresolved assumptions. Do not invent precision.
- Ask for targeted measurements or additional photographs when uncertainty
  materially affects the model. Explain what each measurement or view resolves.
- Validate a simple blockout from several viewpoints before detailed modelling.

Complete this stage with an evidence-backed layout, a scale basis and explicit
assumptions for consequential missing information.

## 2. Check architectural and functional coherence

Treat the space as a connected building, not a collection of independent room
models.

- Verify that rooms connect through consistent openings on both sides of each
  shared wall. Check wall thicknesses, floor levels and usable circulation.
- For a single-room reconstruction, preserve its openings, jambs, thresholds and
  visible door hardware even when the adjacent rooms are outside scope.
- Account for each referenced door, frame, handle and hinge. Verify opening
  direction, attachment and clearance.
- Follow skirting boards and cornices where shown. Check continuity through
  corners and correct termination at openings, fitted units and other joins.
- Look deliberately for light switches, sockets and other wall fittings.
  Locate them relative to doors, furniture and nearby architectural features.
- Distinguish features absent from the references from features merely hidden
  or unclear. Flag consequential uncertainty rather than silently omitting it.

For kitchens and other fitted spaces:

- Reconcile cabinet runs, corners, fillers, end panels, worktops and appliance
  openings as one assembly.
- Check the positions of sinks, taps, appliances, extraction and visible utility
  connections against all available references.
- Verify drawer and cupboard fronts, handle placement and appliance orientation.
- Check that doors and drawers can open, appliances fit their openings, and
  adjacent components meet without unexplained gaps or intersections.
- Keep inferred or concealed service routes labelled as assumptions.

Review completeness and connectivity in a plan or overview, then inspect
openings, corners and fitted assemblies from useful interior viewpoints.

## 3. Inventory and research objects

For each major or visually prominent object, identify:

- Likely product or object type, dimensions and proportions.
- Distinctive silhouette and construction.
- Material, finish and wear.
- Details that catch light or create contact shadows.
- Whether to model it, generate it procedurally or obtain an existing asset.

Search for product photographs, dimensions, alternative views and suitable
existing models before spending substantial effort on an approximation.
Check downloaded assets for scale, geometry, materials and licence suitability.

When a product is named, establish its variant and overall dimensions from the
manufacturer, then inspect its construction in photographs or drawings. A found
image URL or product description does not establish visual inspection. Record
unverified section dimensions separately: overall size alone cannot determine
tabletop thickness, leg width, joinery or flute spacing. Recheck neighbouring
objects and attached props when a verified product changes the blockout size.

If identity or construction remains unclear after research, request close-up
references rather than inventing prominent features. Specify the useful angle:
underside, rear, joint, edge profile or surface detail.

## 4. Model construction and relationships

Box approximations are for blocking out. Finished prominent objects need
reference-supported silhouettes, thicknesses, curves and connections.

Include light-catching details early: bevels, piping, seams, woven structures,
recessed joints, rims and panel transitions. Materials cannot compensate for
missing construction.

Describe relationships explicitly:

- What supports each part?
- Which surfaces touch, overlap intentionally or remain clear?
- Where do hinges, pivots and attachment points lie?
- Which parts move together?
- Which local axis is the front, and what should it face?

For seating groups, identify the open/front side of each chair and aim it toward
the reference's conversation or table centre. Measure the edge-to-edge gap to
the table and the remaining circulation space separately. A positive gap alone
does not establish usable circulation. For nesting furniture, verify that the
smaller top clears the larger table's legs as well as its underside.

Parent components to meaningful assemblies. Place functional pivots at their
actual axes. Keep attached detail following its host when the host moves or
deforms; piping must follow finished cushion edges, not a nominal box.

Verify relationships as well as individual meshes. A valid object can still
float, intersect another object or obstruct an opening.

## 5. Use native modelling tools

Choose editable construction methods suited to the target software.

In Blender, use:

- Subdivision with suitable topology and edge support for controlled curves.
- Bevel and Solidify for edge profiles and thickness.
- Array and Mirror for repetition and symmetry.
- Curves for piping, cables and tubular structures.
- Geometry Nodes for repeated or variable structures such as woven strands,
  books and floorboards.
- Reusable scripts or generators for repeatable construction and updates.

Expose meaningful dimensions and parameters. Avoid manually constructing
repetitive geometry when a procedural approach is clearer and more reliable.
Inspect the evaluated result; a modifier does not guarantee an accurate shape.

## 6. Give props credible detail

Small props contribute substantially to realism. Research mugs, jars, bottles,
books and other visible items instead of populating the scene with generic
repeated shapes.

Include relevant wall thickness, openings, contents, labels, bindings and wear.
When exact identity is not required, use a convincing reference-based substitute
that suits the scene. Preserve exact identity where the user requires it.

Model the distinctive construction of prominent props. A filament bulb needs
the correct envelope profile, cap, internal supports and visible filament. A
large planter needs its shoulder, belly, foot, rim thickness, cavity and planting
depth reconciled with the reference. Review these in a close-up before relying
on their appearance in the room view.

Allocate detail according to visibility, prominence and final viewing distance.

## 7. Plan simulation and placement

Identify simulation needs before building the final geometry.

Distinguish fitted upholstery, loose pillows, blankets and towels. Establish
panel construction, seams, support, stiffness and attachment points before
simulating. Decorative piping alone does not constrain cloth.

Use cloth simulation to refine a plausible starting arrangement. Use basic
rigid-body settling where gravity can improve the placement of loose props.
Preserve deliberate arrangements shown in the references.

For upholstered furniture, pillows or layered bedding, follow
[Textile construction and contact](references/textiles.md) before detailing or
simulating. It covers support, backward pillow lean, layer order, outside drape,
material-specific fold behaviour and finished hem clearance.

Provide appropriate collision geometry and inspect the evaluated surfaces after
simulation, smoothing, subdivision and thickness. Check support, intersections,
excessive stretching, edge sag and the final pose. A completed simulation is not
evidence of a convincing result. Preserve the accepted pose in a reproducible
cache or editable baked state and verify that it survives reopening the file.

## 8. Specify materials beyond colour

For each important surface, describe:

- Underlying material and coating.
- Roughness, sheen, reflection and transmission.
- Grain, weave, pores or other surface structure at physical scale.
- Scratches, scuffs, abrasion, fading and variation.

Separate similar-looking materials with different finishes: unvarnished stained
wood and wood-effect laminate should not share the same surface response.

Identify artwork's medium and mounting before modelling it: framed print, glazed
picture and acrylic on stretched canvas have different edges, depth and surface
response. Match the reference's composition, value distribution and colour
transitions as well as its aspect ratio. For painted canvas, account for weave,
paint relief and wrapped edges. A generic gradient is only a placeholder until
it has been compared against the actual artwork reference.

When coordinating colours across objects, compare their light, midtone and dark
regions under the same illumination. Preserve each object's material response;
matching a planter to a painting's palette should retain its ceramic or stone
texture and the reference's distribution of wear and mottling.

Use suitable PBR textures with correct mapping, colour-space interpretation
and scale. Keep geometry, colour variation, roughness and relief purposeful;
avoid indiscriminate noise.

Review materials both close up and at the final camera distance. Detail that
disappears in the intended render has not yet achieved its purpose.

## 9. Reconstruct daylight, then choose its mood

Inspect available photographic metadata for useful camera, time and location
clues. Treat missing or uncertain metadata explicitly; location alone does not
establish camera direction or window orientation.

Combine references with available map, satellite, street-level or appropriately
licensed 3D sources to estimate exterior context. Prioritise nearby buildings,
trees, walls and sky openings that block or reflect light.

Calibrate materials under neutral daylight first. Then develop an aesthetic
lighting setup—often worth exploring at golden hour—consistent with the scene's
orientation and exterior. Do not use warm lighting to conceal material errors.

Select an appropriate HDRI or sky setup and check its direction and exposure.
If outside detail should be obscured, define whether the glazing is physically
frosted or a presentation effect, and preserve the intended lighting behaviour.
Inspect windows, mirrors and exposed bulbs for unintended softbox reflections
or transmission artifacts. Correct the responsible light's visibility without
removing the material's intended reflection or transmission.

## 10. Validate progressively and preserve decisions

Review in stages:

1. Scale, layout, architectural completeness and connectivity.
2. Silhouette, construction, parenting and contact.
3. Simulation and placement.
4. Materials under controlled lighting.
5. Final lighting and composition.

Use diagnostic views that expose the relevant issue. A room render cannot
certify hidden joins, attached seams or texture quality.

For each user correction, record the expected visible result or relationship,
update the owning generator and scene, then check it from a view that exposes
the defect. Use evaluated geometry for measured clearances and collision checks;
bounding boxes are broad-phase checks, not proof of surface contact. Check both
intersections and floating gaps. Preserve accepted corrections when rebuilding.
Treat subsequent notes as additions to this correction list unless they replace
an earlier requirement. Keep numerical requests as explicit model parameters and
acceptance checks rather than approximating them by eye.

For noise, smudging or shading artifacts, compare small crops and change one
variable at a time. Establish the cause before altering unrelated materials or
geometry. Produce the final high-resolution render after these checks.
Compare corrected silhouettes and finishes with the reference from a similar
angle. A successful script run or finished render proves execution, not fidelity.

Maintain one authoritative scene, with recoverable checkpoints and reproducible
render presets or scripts. Keep corrections in the owning source so rebuilds
do not restore old mistakes.

Maintain an inventory of requested views and their output paths. When asked to
refresh all images, regenerate every preview and final output in that inventory,
including newly requested viewpoints and detail views. Previews may be resized
from current final renders. Verify successful outputs against the saved scene
revision, inspect the views relevant to the corrections, and account explicitly
for any failed or deferred output before declaring the refresh complete.

Report what was checked, what remains uncertain and what is still approximate.
Do not claim whole-scene correctness from a limited review.
