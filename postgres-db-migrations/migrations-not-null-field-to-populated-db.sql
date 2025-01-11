-- Step 1: Create workspaces table with minimal fields
CREATE TABLE workspaces (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    CONSTRAINT unique_workspace_name UNIQUE (name) WHERE deleted_at IS NULL
);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_workspaces_updated_at
    BEFORE UPDATE ON workspaces
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Step 2: Create workspaces for each machine with simple numbering
INSERT INTO workspaces (name)
SELECT 'Workspace ' || ROW_NUMBER() OVER (ORDER BY id)
FROM machines;

-- Step 3: Add workspace_id to machines
ALTER TABLE machines
ADD COLUMN workspace_id INTEGER;

-- Step 4: Map each machine to a workspace (simplified to match by row number)
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

-- Step 5: Add constraints
ALTER TABLE machines
ALTER COLUMN workspace_id SET NOT NULL;

ALTER TABLE machines
ADD CONSTRAINT fk_machine_workspace
FOREIGN KEY (workspace_id) REFERENCES workspaces(id);

-- Add unique constraint to ensure 1:1 relationship
ALTER TABLE machines
ADD CONSTRAINT unique_workspace UNIQUE (workspace_id);