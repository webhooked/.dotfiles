# Textile construction and contact

Use this workflow for upholstered furniture, loose cushions, blankets and layered
bedding. Finish with supported, collision-free evaluated surfaces and close-ups
that demonstrate the requested silhouette and drape.

## 1. Establish the support and layer order

Inventory the visible components separately: divan, exposed feet, mattress,
headboard, sleeping pillows, decorative pillows, duvet, folded-back lip,
bedspread and loose throw. Identify which surface supports each component.

- Model headboard tufts as padded recesses with fabric tension around the buttons.
  Buttons placed on a flat box do not create upholstery construction.
- Give a duvet filled loft, soft edge compression and a credible turned-back edge.
  Give a woven coverlet its own thinner body, weave and hem.
- Derive prominent pillow counts, proportions, overlap and placement from the
  reference. Model nearby bedside furniture as a complete assembly, including
  shelf depth, top thickness, panel supports and the clearance to hanging bedding.

**Done when:** the visible stack and its supporting surfaces are identified and
the reference's major components have distinct editable geometry.

## 2. Construct and place loose pillows

Use lofted sewn panels with a pinched perimeter, soft corners and reference-sized
seams or piping. Allow local fabric tension without making the whole cushion a
rigid slab. Match its width-to-height ratio and fullness from front and side views.

Define front and back in the assembly's local coordinates before setting its
lean. A pillow resting against a backrest has its upper portion leaning toward
that support and its lower portion resting on the seat or bedding.

Check these contacts independently:

1. Lower edge against the evaluated seat or duvet surface.
2. Rear face against the evaluated backrest or supporting pillow.
3. Side edges against arms, neighbouring pillows and headboard.

A small pillow can clear the mattress while still sinking into the duvet. Check
the actual supporting layer. An intersection-free pillow may still be floating;
inspect the contact shadow and measure the closest supporting gap.

**Done when:** front and side views show the intended lean, believable support
and no unintended penetration after subdivision, deformation and seam placement.

## 3. Drape fabric around the outside envelope

Build the starting arrangement around the actual rounded outer surfaces. Include
the full side and foot extents of the mattress, frame and lower fabric layers.
Cloth hanging at the nominal mattress edge can pass through the wider divan or
through the projecting layer underneath it.

- Use a continuous rounded transition from the supported top to the hanging part.
- Give folds varied spacing, direction and amplitude appropriate to the reference.
- Check both long sides, the foot end and their corners. Combining side and foot
  drop must preserve fabric length and floor clearance at the corners.
- Keep each outer layer outside the finished envelope of the layers below it.
  Independently generated wave patterns can intersect despite different base
  heights. Use collision-aware settling or a shared support surface with controlled
  offsets and localized independent folds.
- For requested coverage, identify whether the user means a narrow runner, a
  full-width coverlet or a floor-length bedspread. Verify coverage in plan and at
  the foot end rather than inferring it from the fabric's nominal width.
- Measure a specified hem clearance from the finished floor surface to the
  evaluated lower fabric surface, including Solidify thickness and subdivision.
  For example, a requested 2 cm gap is above the flooring, not above world zero.

**Done when:** bedding covers the requested surfaces, hangs outside the bed and
underlying textiles, and meets the requested finished hem clearance.

## 4. Match the fabric's physical behaviour

Distinguish wool, linen, cotton, duvet filling and fitted upholstery before
choosing simulation settings. Set visible thickness, bending resistance, mass,
friction and pinning together; increasing thickness alone does not create wool.

Start from a plausible drape and use gravity to settle it against appropriate
collision surfaces. Anchor only the genuinely tucked or supported region.
Inspect for tight buckles, isolated bumps, hard elbows and repetitive ridges.

When artifacts appear, diagnose their source in a small crop: initial cloth
compression, collision margin, excessive friction, pinning or insufficient bending
resistance. Change one cause at a time. Broad smoothing can refine accepted folds,
but its result must be checked for renewed penetration and lost edge clearance.
Preserve the hem's thickness and the fabric's recognizable weave at render scale.

**Done when:** the cloth reads as the intended material, follows its supports,
and retains a credible pose after the complete modifier stack is evaluated.

## 5. Verify contact and preserve the accepted result

Use side, foot-end and close-up views, temporarily hiding obstructing curtains
or foreground furniture for diagnostics. Restore presentation visibility in the
authoritative scene or keep diagnostic visibility changes in render presets.

Combine visual review with targeted evaluated-mesh checks. Broad-phase bounding
boxes can locate candidates; surface queries or mesh intersections resolve actual
contact. Signed-distance tests require coherent normals and appropriate closed
surfaces. Report the pairs checked and the tolerances used rather than treating a
partial sample as whole-scene certification.

Check textiles against furniture **and against each other**. Pale slivers or
patches breaking through a darker spread often indicate an underlying layer
intersecting it. Inspect floating gaps as well as penetrations.

Preserve the accepted simulation as an editable baked mesh, shape key or reliable
cache. Keep rest poses, meaningful parameters and enough provenance to reproduce
the result. Reopen or rebuild, verify the pose persists, then refresh its affected
detail and room renders through the main skill's output inventory.
