-- Step 1: Create workspaces with auto-generated IDs
INSERT INTO workspaces (name)
SELECT 'Workspace for Machine ' || id::text
FROM machines;

-- Step 2: Add workspace_id to machines
ALTER TABLE machines
ADD COLUMN workspace_id INTEGER;

-- Step 3: Map each machine to a workspace (using row_number to match them up)
WITH workspace_mapping AS (
    SELECT 
        id as workspace_id,
        ROW_NUMBER() OVER (ORDER BY id) as rn
    FROM workspaces
),
machine_numbers AS (
    SELECT 
        id as machine_id,
        ROW_NUMBER() OVER (ORDER BY id) as rn
    FROM machines
)
UPDATE machines m
SET workspace_id = wm.workspace_id
FROM machine_numbers mn
JOIN workspace_mapping wm ON mn.rn = wm.rn
WHERE m.id = mn.machine_id;

-- Step 4: Add constraints
ALTER TABLE machines
ALTER COLUMN workspace_id SET NOT NULL;

ALTER TABLE machines
ADD CONSTRAINT fk_machine_workspace
FOREIGN KEY (workspace_id) REFERENCES workspaces(id);

-- Add unique constraint to ensure 1:1 relationship
ALTER TABLE machines
ADD CONSTRAINT unique_workspace UNIQUE (workspace_id);
