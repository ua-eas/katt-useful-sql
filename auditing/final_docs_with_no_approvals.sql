--
-- "final_docs_with_no_approvals.sql"
-- (M. Simpson, 3/29/2013)
--
-- This query pulls a list of UAccess Financials (KFS 3.0) documents
-- that have reached "Final" status without an approval action being
-- recorded for them.
--
-- The columns returned are:
--
--   doc_id          document identifier
--   doc_type_name   document type name
--   doc_type_label  document type label
--   init_netid      initiator NetId
--   init_name       initiator name
--   created         document creation date
--   approved        document approval date
--   finalized       document finalized date
--
-- Notes:
--
-- * For the definition of "documents with recorded approvals", we are 
--   including the following KFS action codes: "A" (approved), "B" 
--   (blanket approved), "v", "r", and "a" (different types of super-user
--   approval). 
--
-- * Results are sorted numerically by document identifier. 
--

select
    -- Document information from main document tables.
    dh.doc_hdr_id                     as doc_id,
    dt.doc_typ_nm                     as doc_type_name,
    dt.lbl                            as doc_type_label,
    -- Initiator information from entity cache table.
    e.prncpl_nm                       as init_netid,
    e.last_nm || ', ' || e.first_nm   as init_name,
    -- Document dates from document header table.
    dh.crte_dt                        as created, 
    dh.aprv_dt                        as approved,
    dh.fnl_dt                         as finalized
from
    -- Start with all finalized documents.
    ( select 
          *
      from
          krew_doc_hdr_t 
      where
          doc_hdr_stat_cd = 'F' ) dh
    -- Join to main document type table for type information.          
    join krew_doc_typ_t dt  
      on dh.doc_typ_id = dt.doc_typ_id
    -- Join to entity cache for initiator information.
    left join krim_entity_cache_t e
           on dh.initr_prncpl_id = e.prncpl_id  
where
    -- Trim rows where we see an approval action recorded.
    dh.doc_hdr_id not in ( select distinct 
                               doc_hdr_id
                           from
                               krew_actn_tkn_t
                           where
                               actn_cd in ( 'A','v','r','a','B' ) )
order by
    -- Sort by document identifier.
    dh.doc_hdr_id
;