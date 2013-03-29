--
-- "gec_against_fed_subfund.sql"
-- (M. Simpson, 3/29/2013)
--
-- This query pulls a list of UAccess Financials (KFS 3.0) documents
-- that represent GEC transactions against Federal subfund accounts.
--
-- The columns returned are:
--
--   doc_type        document type
--   doc_id          document identifier
--   init_netid      initiator NetId
--   init_name       initiator name
--   created         document creation date
--   approved        document approval date
--   finalized       document finalized date
--   line_type       accounting line item type
--   line_nbr        accounting line item number
--   fin_coa_cd      financial chart-of-accounts code
--   account_nbr     account number
--   obj_cd          object code
--   line_amt        line item amount
--
-- Notes:
--
-- * The inclusion of doc_type is redundant, since we should only
--   be pulling GEC documents; it is included as a sanity check on
--   the SQL query.
--
-- * For the definition of "Federal subfund account", we are
--   including the following KFS subfund group codes: "AGFED",
--   "FEDSUB", "FWSGRT", and "HATCH".
--
-- * Results are sorted numerically by document identifier, then
--   by acounting line type and accounting line number, then by
--   account and object code.
--

select
    -- Document information from main document tables.
    dt.doc_typ_nm                                as doc_type,
    dh.doc_hdr_id                                as doc_id,
    -- Initiator information from the entity cache table.
    ec.prncpl_nm                                 as init_netid,
    ec.last_nm || ', ' || ec.first_nm            as init_name,
    -- Document date from document header table.
    dh.crte_dt                                   as created,
    dh.aprv_dt                                   as approved,
    dh.fnl_dt                                    as finalized,
    -- Line item information from the accounting line table.
    al.fdoc_ln_typ_cd                            as line_type,
    al.fdoc_line_nbr                             as line_nbr,
    al.fin_coa_cd                                as fin_coa_cd,
    al.account_nbr                               as acct_nbr,
    al.fin_object_cd                             as obj_cd,
    to_char( al.fdoc_line_amt, '$9,999,999.00' ) as line_amt
from
    -- Start with all finalized documents.  Note that we're
    -- generating an extra "fdoc_nbr" column as a VARCHAR
    -- transform of the "doc_hdr_id" field -- this is because
    -- we have to join against the accounting line item table,
    -- which treats the document identifier as a VARCHAR2.
    ( select
          krew_doc_hdr_t.*,
          to_char( doc_hdr_id ) as fdoc_nbr
      from
          krew_doc_hdr_t
      where
          doc_hdr_stat_cd = 'F' ) dh
    -- Join to document type table to get the type name.
    join ( select
               *
           from
               krew_doc_typ_t
           where doc_typ_nm = 'GEC' ) dt
      on dh.doc_typ_id = dt.doc_typ_id
    -- Join to the accounting lines table for line item information.
    join fp_acct_lines_t al
      on dh.fdoc_nbr = al.fdoc_nbr
    -- Join to the entity cache table for initiator information.
    left join krim_entity_cache_t ec
      on dh.initr_prncpl_id = ec.prncpl_id
where
    -- Screen for documents related to Federal subfund accounts.
    dh.fdoc_nbr in ( select distinct
                         alt.fdoc_nbr
                     from
                         fp_acct_lines_t alt
                         join ( select
                                    *
                                from
                                    ca_account_t
                                where
                                    sub_fund_grp_cd in ( 'AGFED', 'FEDSUB', 'FWSGRT', 'HATCH' ) ) a
                           on alt.fin_coa_cd = a.fin_coa_cd and
                              alt.account_nbr = a.account_nbr )
-- Sort on document identifier, then line information, the account information.
order by
    dh.doc_hdr_id,
    al.fdoc_ln_typ_cd,
    al.fdoc_line_nbr,
    al.fin_coa_cd,
    al.account_nbr,
    al.fin_object_cd
;