--
-- "all_account_delegates.sql"
-- (M. Simpson, 3/29/2013)
--
-- This query pulls a list of UAccess Financials (KFS 3.0) accounts,
-- and shows fiscal officers and delegates associated with them.
--
-- The columns returned are:
--
--   fin_coa_cd     financial chart-of-accounts code
--   account        the account name and number
--   organization   the associated organization name and number
--   fo_netid       the associated fiscal officer's NetId
--   fo_name        the associated fiscal officer's name
--   dlgt_netid     delegate NetId
--   dlgt_name      delegate name
--   dlgt_dept_cd   delegate department code
--   fdoc_type_cd   document type associated with the delegation
--   dlgt_type      delegation type, either "Primary" or "Secondary"
--   aprv_from_amt  dollar value low bound on delegated approvals
--   aprv_to_amt    dollar value high bound on delegated approvals
--
-- Notes:
--
-- * The inclusion "fin_coa_cd" is redundant -- according to FSO, we only
--   ever have accounts on the "UA" code -- but is included as a sanity 
--   check on the query.
--
-- * Results are sorted by account name, then document type, showing
--   (for each type) primaries first, then secondaries.
--

select
    -- Account and organization data pulled from associated main tables.
    ad.fin_coa_cd                                 as fin_coa_cd,
    a.account_nm || ' (' || ad.account_nbr || ')' as "ACCOUNT",
    o.org_nm || ' (' || a.org_cd || ')'           as "ORGANIZATION",
    -- Fiscal officer information from entity cache table (1st join).
    fe.prncpl_nm                                  as fo_netid,
    fe.last_nm || ', ' || fe.first_nm             as fo_name,
    -- Delegate information from entity cache table (2nd join).
    de.prncpl_nm                                  as dlgt_netid,
    de.last_nm || ', ' || de.first_nm             as dlgt_name,
    de.prmry_dept_cd                              as dlgt_dept_cd,
    -- Delegation information from the account delegates table.
    ad.fdoc_typ_cd                                as fdoc_type_cd,
    ( case acct_dlgt_prmrt_cd
          when 'Y' then 'Primary'
          when 'N' then 'Secondary'
      end )                                       as dlgt_type,
    ad.fdoc_aprv_from_amt                         as aprv_frm_amt,
    ad.fdoc_aprv_to_amt                           as aprv_to_amt
from
    -- Start with all currently active delegations.
    ( select 
          *
      from 
          ca_acct_delegate_t
      where
          acct_dlgt_actv_cd = 'Y' and 
          acct_dlgt_start_dt <= current_timestamp ) ad
    -- Join to entity cache table on delegate's prncpl_id.
    left join krim_entity_cache_t de
           on ad.acct_dlgt_unvl_id = de.prncpl_id
    -- Join on fin_coa_cd and account_nbr to pull in account information.
    inner join ca_account_t a
            on ad.fin_coa_cd = a.fin_coa_cd and
               ad.account_nbr = a.account_nbr
    -- Join on fin_coa_cd and org_cd to pull in organization information.
    inner join ca_org_t o
            on a.fin_coa_cd = o.fin_coa_cd and
               a.org_cd = o.org_cd
    -- Join (again) to entity cache table on fiscal officer's prncpl_id.
    left join krim_entity_cache_t fe
           on a.acct_fsc_ofc_uid = fe.prncpl_id
order by
    -- Sort by accounts, the document types, then primary vs. secondary delegates.
    fin_coa_cd,
    "ACCOUNT",
    fdoc_type_cd,
    dlgt_type,
    dlgt_netid
;