# ZCL_DEMO_KI – EWM HU Movement Class

## Overview

`ZCL_DEMO_KI` is an SAP EWM ABAP class that exposes the method `MOVE_HU`.  
The method creates a **Warehouse Task (WT)** with **movement type 9999** to relocate a
Handling Unit (HU) from its current storage bin to a specified destination bin.

---

## Method: MOVE_HU

### Signature

| Direction  | Parameter      | Type              | Description                          |
|------------|---------------|-------------------|--------------------------------------|
| IMPORTING  | `IV_LGNUM`     | `/SCWM/LGNUM`     | Warehouse number                     |
| IMPORTING  | `IV_HUIDENT`   | `/SCWM/HUIDENT`   | HU licence-plate / identification    |
| IMPORTING  | `IV_LGPLA_DEST`| `/SCWM/LGPLA`     | Destination storage bin              |
| EXPORTING  | `ET_BAPIRET`   | `BAPIRETTAB`      | Return messages (errors / success)   |

### Processing steps

1. **Read HU header** – calls `/SCWM/HU_READ_SINGLE` to retrieve the current  
   storage bin of the HU (field `LGPLA` from structure `/SCWM/HUHDR`).
2. **Build the WT request line** – fills one entry of table type  
   `/SCWM/TT_LTAP_VB` with:
   - `BWLVS = '9999'` (movement type)
   - `VLPLA` = source bin (from the HU header)
   - `NLPLA` = destination bin (caller input)
   - `NLENR` = HU identification
   - `TOHU = 'X'` (HU-relevant warehouse task flag)
3. **Create the warehouse task** – calls `/SCWM/TO_CREATE` with `IV_COMMIT = 'X'`
   so that the WT is persisted to the database in the same call.

---

## Sources and SAP EWM objects used

### Function modules

| FM | Package | Purpose |
|----|---------|---------|
| `/SCWM/HU_READ_SINGLE` | `/SCWM/HU` | Read a single HU header record by warehouse + HU identification. Returns `/SCWM/HUHDR` which contains the current storage bin (`LGPLA`). |
| `/SCWM/TO_CREATE` | `/SCWM/WT_CREATION` | Create one or more warehouse tasks. The caller populates the change-parameter table `CT_LTAP_VB` (type `/SCWM/TT_LTAP_VB`) and the FM writes the resulting `/SCWM/LTAP` database records. |

### DDIC types used

| Object | Kind | Description |
|--------|------|-------------|
| `/SCWM/LGNUM` | Data element | Warehouse number (4-char) |
| `/SCWM/HUIDENT` | Data element | HU identification / licence plate |
| `/SCWM/LGPLA` | Data element | Storage bin |
| `/SCWM/HUHDR` | Structure | HU header; field `LGPLA` holds the current bin |
| `/SCWM/LTAP_VB` | Structure | Warehouse task request line (one WT item) |
| `/SCWM/TT_LTAP_VB` | Table type | Internal table of `/SCWM/LTAP_VB` |
| `BAPIRETTAB` | Table type | Standard BAPI return table (type, id, number, message) |

### Movement type 9999

Movement type **9999** is used in EWM for **ad-hoc / unplanned HU relocations**
within the same warehouse. It must exist in Customizing:

> SAP Customizing → Extended Warehouse Management → Goods Movements → Warehouse Task  
> → **Define Movement Types** (transaction `/SCWM/MOVE_TYP`)

The movement type controls which process is triggered (stock changes, confirmation
behaviour, etc.). Movement type 9999 is a common demo / development placeholder;
in a productive system it would be replaced with a project-specific movement type.

### Reference documentation

- SAP Help Portal – *EWM: Creating Warehouse Tasks Programmatically*  
  <https://help.sap.com/docs/SAP_EXTENDED_WAREHOUSE_MANAGEMENT>
- SAP Note **2188695** – EWM: Creating warehouse tasks via function module `/SCWM/TO_CREATE`
- ABAP keyword documentation – `CALL FUNCTION` exception handling

---

## abapGit file layout

```
src/
├── zcl_demo_ki.clas.abap   ← Class definition + implementation (single-file format)
└── zcl_demo_ki.clas.xml    ← abapGit metadata (class properties, language, exposure)
```

> The single-file format (one `.clas.abap` containing both `DEFINITION` and
> `IMPLEMENTATION`) is supported by abapGit ≥ 1.100 and ABAP ≥ 7.40 SP08.
