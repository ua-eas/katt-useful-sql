--
-- "roles_and_groups_by_netid.sql"
-- (M. Simpson, 3/26/2013)
--
-- This query pulls a list of groups and roles associated with each NetId
-- known to UAccess Financials (KFS 3.0).
--
-- The columns returned are:
--
--   net_id      employee NetId
--   empl_id     corresponds to employee EmplId
--   empl_name   employee name in “Last, First” format
--   cntr_type   container type, either “Role” or “Group” as appropriate
--   cntr_nmspc  the KFS namespace of the role or group
--   cntr_name   the KFS name of the role or group
--   cntr_id     the KFS internal role_id or grp_id for the role or group
--
-- Notes:
--
-- * The data is sorted first by NetId, then by container type (groups first, then roles),
--   then by namespace and name.  So you should be able to bump to a specific NetId and
--   see all of the Group and Role assignments currently set in KFS.
--
-- * Note that these are “top-level” role and group assignments, e.g. the provisioning 
--   of specific people into specific roles and groups.  Not included are the nested 
--   roles and groups that occur because KFS lets you put roles into groups, groups into
--   roles, people into either, etc. – the SQL to include all of the nesting was becoming 
--   increasingly unwieldy, and for the specific purpose of this report (de-provisioning
--   folks who have left UA employment) you only need the top-level assignments; once you
--   take them out of those, they’ll automatically lose the nested roles and groups as well.
--
-- * Note as well that the four “derived roles” are not included; these roles only exist 
--   during a specific user’s login session, and are dynamically assigned based on
--   information taking from their LDAP record.  The only way to include that information 
--   would be to take an identically-dated extract from the campus LDAP directory and join
--   across it, including the logic encoded in the associated KFS code and parameter 
--   settings.  Again, for the specific purpose of this report, so long as their EDS data 
--   is updated, the derived roles should take care of themselves.  Full information on 
--   the derived role functionality is available via the Kuali Application Technical Team
--   wiki, under the title "EDS Functional Description".
--
-- * More generally, this output now matches exactly what you see through the KFS interface
--   if you pull up a specific Person record, and look under the “Memberships” tab.
--

-- Assemble role membership information.
select distinct
    -- Person data pulled from the entity cache table.
    e.prncpl_nm as net_id,
    e.emp_id as empl_id,
    e.last_nm || ', ' || e.first_nm as empl_name,
    -- Hardcoded container type of "Role" for this half of the union.
    'Role' as cntr_type,
    -- Role information from the main role and role memberships tables.
    r.nmspc_cd as cntr_nmspc,
    r.role_nm as cntr_name,
    rm.root_role_id as cntr_id
from
    -- Start with person ("P") rows from the convenience view that
    -- unrolls nested role memberships.
    ( select
          *
      from
          kulowner.ua_krim_role_mbr_v
      where
          mbr_typ_cd = 'P' ) rm
    -- Join on root_role_id to to the main roles table to bring in
    -- basic role information.
    join kulowner.krim_role_t r
      on rm.root_role_id = r.role_id
    -- Join on mbr_id to the entity cache table to bring in person
    -- information.
    join kulowner.krim_entity_cache_t e
      on rm.mbr_id = e.prncpl_id
where
    -- Limit to "top-level" (non-nested) role memberships.
    rm.depth = 1

-- all of the above
union
-- plus what follows

-- Assemble group membership information.
select distinct
    -- Person data pulled from the entity cache table.
    e.prncpl_nm as net_id,
    e.emp_id as empl_id,
    e.last_nm || ', ' || e.first_nm as empl_name,
    -- Hardcoded container type of "Group" for this half of the union.
    'Group' as cntr_type,
    -- Group information from the main group and group memberships tables.
    g.nmspc_cd as cntr_nmspc,
    g.grp_nm as cntr_name,
    gm.root_grp_id as cntr_id
from
    -- Start with person ("P") rows from the convenience view that
    -- unrolls nested group memberships.
    ( select
          *
      from
          kulowner.ua_krim_grp_mbr_v
      where
          mbr_typ_cd = 'P' ) gm
    -- Join on root_grp_id to the main groups table to bring in basic
    -- group information.
    join kulowner.krim_grp_t g
      on gm.root_grp_id = g.grp_id
    -- Join on mbr_id to the entity cache table to bring in person
    -- information.
    join kulowner.krim_entity_cache_t e
      on gm.mbr_id = e.prncpl_id
where
    -- Limit to "top-level" (non-nested) group memberships.
    gm.depth = 1
    
-- Show group memberships, then role memberships, alphabetized by
-- namespace and name, for each net_id in turn.
order by
    net_id,
    cntr_type,
    cntr_nmspc,
    cntr_name
;