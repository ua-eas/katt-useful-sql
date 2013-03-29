--
-- "all_role_54_users.sql"
-- (M. Simpson, 3/26/2013)
--
-- This query pulls a list of UAccess Financials (KFS 3.0) users who are
-- listed in the system as belonging to Role 54.
--
-- The columns returned are:
--
--   net_id      employee NetId
--   empl_id     corresponds to employee EmplId
--   empl_name   employee name in “Last, First” format
--   role_nmspc  the KFS namespace of the role
--   role_name   the KFS name of the role
--   role_id     the KFS internal role_id for the role
--
-- Notes:
--
-- * The inclusion of role information is redundant -- it should always be Role 54,
--   but is included as a sanity check on the query.
--
-- * Results are sorted by NetId.
--

select distinct
    -- Person data pulled from the entity cache table.
    e.prncpl_nm as net_id,
    e.emp_id as empl_id,
    e.last_nm || ', ' || e.first_nm as empl_name,
    -- Role data pulled from the main role and role memberships tables.
    r.nmspc_cd as role_nmspc,
    r.role_nm as role_name,
    rm.role_id as role_id
from
    -- Start with all active roles.
    ( select 
          *
      from
          krim_role_t
      where
          actv_ind = 'Y' ) r 
    -- Join on role_id to active person ("P") memberships in Role 54.
    inner join ( select 
                     * 
                 from
                     krim_role_mbr_t
                 where
                     role_id = '54' and 
                     mbr_typ_cd = 'P' and 
                     ( actv_to_dt is null OR actv_to_dt >= CURRENT_TIMESTAMP ) ) rm 
            on r.role_id = rm.role_id 
    -- Join on mbr_id to entity cache table.
    inner join krim_entity_cache_t e
            on rm.mbr_id = e.prncpl_id 
order by
    -- Alphabetical sort on net_id.
    net_id
;