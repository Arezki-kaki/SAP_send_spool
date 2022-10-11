REPORT ZAAA_CSV_ATTACHMENT_FM.

TABLES: adr6.

*-- Data declaration
DATA: gt_sflight TYPE TABLE OF sflight.


DATA: wa_sflight LIKE LINE OF gt_sflight.

*-- Send e-mail data declaration
DATA: gs_maildata LIKE sodocchgi1.
DATA: gt_mailpack LIKE sopcklsti1 OCCURS 0 WITH HEADER LINE.
DATA: gt_mailhead LIKE solisti1 OCCURS 0 WITH HEADER LINE.
DATA: gt_mailbin LIKE solisti1 OCCURS 0 WITH HEADER LINE.
DATA: gt_mailtxt LIKE solisti1 OCCURS 0 WITH HEADER LINE.
DATA: gt_mailrec LIKE somlrec90 OCCURS 0 WITH HEADER LINE.
DATA: gt_solisti1 LIKE solisti1 OCCURS 0 WITH HEADER LINE.
DATA: v_lines TYPE i.
*-- Selection-screen
SELECTION-SCREEN: BEGIN OF BLOCK a1 WITH FRAME TITLE text-001.

SELECT-OPTIONS: s_email FOR adr6-smtp_addr DEFAULT 'aaa@codilog.fr' NO INTERVALS.

SELECTION-SCREEN: END OF BLOCK a1.

*-- Start-of-selection
START-OF-SELECTION.


*-- Collect data
  PERFORM get_data.

*-- send e-mail with TXT file as attachement
  PERFORM send_email.




END-OF-SELECTION.
*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
* text
*----------------------------------------------------------------------*
* --> p1 text
* <-- p2 text
*----------------------------------------------------------------------*
FORM get_data .

* CLEAR GT_sflight[].
  SELECT *
* INTO CORRESPONDING FIELDS OF TABLE GT_sflight
  INTO TABLE gt_sflight
  FROM sflight.

ENDFORM. " GET_DATA
*&---------------------------------------------------------------------*
*& Form SEND_EMAIL
*&---------------------------------------------------------------------*
* text
*----------------------------------------------------------------------*
* --> p1 text
* <-- p2 text
*----------------------------------------------------------------------*
FORM send_email .

* Creation of the document to be sent File Name
  CLEAR gs_maildata.
  gs_maildata-obj_name = 'E-mail'.
  gs_maildata-obj_descr = 'Send e-mail with CSV attachment'.

* Mail Body
  CLEAR gt_mailtxt.
  gt_mailtxt-line = 'Line 1'.
  APPEND gt_mailtxt.

  CLEAR gt_mailtxt.
  gt_mailtxt-line = 'Line 2'.
  APPEND gt_mailtxt.

  CLEAR gt_mailtxt.
  gt_mailtxt-line = 'Line 3'.
  APPEND gt_mailtxt.

* Prepare Packing List
  CLEAR v_lines.
  DESCRIBE TABLE gt_mailtxt LINES v_lines.
  READ TABLE gt_mailtxt INDEX v_lines.
  gs_maildata-doc_size = ( v_lines - 1 ) * 255 + strlen( gt_mailtxt ).

* Creation of the entry for the compressed document
  CLEAR gt_mailpack-transf_bin.
  gt_mailpack-head_start = 1.
  gt_mailpack-head_num = 0.
  gt_mailpack-body_start = 1.
  gt_mailpack-body_num = v_lines.
  gt_mailpack-doc_type = 'RAW'.
  APPEND gt_mailpack.

  gt_mailhead = 'Attachment.CSV'.
  APPEND gt_mailhead.


* Populate the TXT file
  LOOP AT gt_sflight INTO wa_sflight.
    CONCATENATE wa_sflight-carrid
    wa_sflight-connid
    wa_sflight-fldate
* WA_sflight-PRICE
* WA_sflight-CURRENCY
*    INTO gt_mailbin SEPARATED BY ','.
    INTO gt_mailbin SEPARATED BY ';'.

    APPEND gt_mailbin.
  ENDLOOP.

  CLEAR v_lines.
  DESCRIBE TABLE gt_mailbin LINES v_lines.


  gt_mailpack-transf_bin = 'X'.
  gt_mailpack-head_start = 1.
  gt_mailpack-head_num = 1.
  gt_mailpack-body_start = 1.
  gt_mailpack-body_num = v_lines.
  gt_mailpack-doc_type = 'CSV'.
  gt_mailpack-obj_name = 'Attachment'.
  gt_mailpack-obj_descr = 'Attachment'.
  gt_mailpack-doc_size = v_lines * 255.
  APPEND gt_mailpack.

* Populate recipient
  LOOP AT s_email.
    gt_mailrec-receiver = s_email-low.
    gt_mailrec-rec_type = 'U'.
    APPEND gt_mailrec.
  ENDLOOP.

* Sending the document
  CALL FUNCTION 'SO_NEW_DOCUMENT_ATT_SEND_API1'
    EXPORTING
      document_data              = gs_maildata
      put_in_outbox              = ' '
      commit_work                = 'X'
    TABLES
      packing_list               = gt_mailpack
      object_header              = gt_mailhead
      contents_bin               = gt_mailbin
      contents_txt               = gt_mailtxt
      receivers                  = gt_mailrec
    EXCEPTIONS
      too_many_receivers         = 1
      document_not_sent          = 2
      operation_no_authorization = 4
      OTHERS                     = 99.




ENDFORM. " SEND_EMAIL
