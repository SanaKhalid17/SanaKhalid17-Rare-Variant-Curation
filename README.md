# ACMG-Guided Interpretation of Rare Disease Variants

![GRCh38](https://img.shields.io/badge/Genome-GRCh38-blue)
![ACMG/AMP](https://img.shields.io/badge/ACMG%2FAMP-Pathogenicity%20Framework-red)
![ClinVar](https://img.shields.io/badge/Annotation-ClinVar-orange)
![OMIM](https://img.shields.io/badge/Phenotype-OMIM-purple)
![AlphaMissense](https://img.shields.io/badge/Predictor-AlphaMissense-darkgreen)
![REVEL](https://img.shields.io/badge/Predictor-REVEL-darkgreen)
![bcftools](https://img.shields.io/badge/Tool-bcftools-lightgrey)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

## 1) Project summary

This repository contains an end-to-end, reproducible mini-pipeline for interpreting rare disease variants. Three monogenic disorders were selected, and for each disorder one clinically relevant pathogenic variant was curated from ClinVar and summarized in a structured Excel report. Variant-level interpretation integrates:

* ClinVar variant record review (classification + supporting observations)
* OMIM phenotype confirmation for gene/disease context
* UCSC Genome Browser pathogenicity predictors (AlphaMissense and REVEL) with screenshot evidence
* ACMG/AMP evidence codes documented in the report
* A working VCF-based workflow using `bcftools` + ClinVar VCF annotation, ending in a filtered “Pathogenic / Likely_pathogenic” VCF

Deliverables included:

* A curated Excel report: `Clinical_Variant_Annotation_Report.xlsx`
* A “patient-like” input VCF with the three variants: `patient_variants.vcf`
* A ClinVar-annotated, final filtered VCF: `patient_final_filtered.vcf`
* A shell pipeline implementing the filtering + ClinVar annotation logic: `pipeline.sh`
* UCSC screenshot evidence for AlphaMissense and REVEL scores (provided as PNGs)

## 2) Disorders and curated variants (from the Excel report)

Three rare genetic disorders were curated, each with a top pathogenic SNV:

| Disorder                      | Gene | Curated variant (HGVS)                            | Consequence | ClinVar classification |
| ----------------------------- | ---- | ------------------------------------------------- | ----------- | ---------------------- |
| Cystic Fibrosis               | CFTR | NM_000492.4(CFTR): c.1652G>A (p.Gly551Asp; G551D) | SNV (1 bp)  | Pathogenic             |
| Familial Hypercholesterolemia | LDLR | NM_000527.5(LDLR): c.681C>G (p.Asp227Glu; D227E)  | SNV (1 bp)  | Pathogenic             |
| Phenylketonuria (PKU)         | PAH  | ClinVar VCV000000577.141; PAH p.Arg408Trp (R408W) | SNV (1 bp)  | Pathogenic             |

Phenotype links (OMIM) are recorded in the Excel report under the “Phenotype (OMIM)” field.

## 3) Inputs and outputs

### Input VCF

Contains three heterozygous variants (GT = 0/1), one per gene. The file uses `chr`-prefixed contigs:

* chr7:117587806 G>A (CFTR region)
* chr12:102840493 G>A (PAH region)
* chr19:11105587 C>G (LDLR region)

### Final filtered VCF

This is the ClinVar-annotated and filtered output containing **only variants with `CLNSIG=Pathogenic`**. It includes ClinVar INFO fields:

* `CLNSIG=Pathogenic`
* `CLNDN=...` (ClinVar preferred disease names; multiple entries separated by `|`)

The output shows the same three loci (now using non-`chr` contigs: 7/12/19), and all three are retained as Pathogenic.

## 4) UCSC pathogenicity predictor evidence

For each curated variant, UCSC Genome Browser tracks were used to capture AlphaMissense and REVEL scores. The PNG screenshots in this repository document the exact values:

| Disorder / Gene |     Predictor | Score (from screenshot) | Evidence file   |
| --------------- | ------------: | ----------------------: | --------------- |
| CFTR (CF)       |         REVEL |                    0.99 | `CF_revel.png`  |
| CFTR (CF)       | AlphaMissense |                  0.9897 | `CF_Alpha.png`  |
| LDLR (FH)       |         REVEL |                   0.864 | `FH_revel.png`  |
| LDLR (FH)       | AlphaMissense |                  0.9881 | `FH_Alpha.png`  |
| PAH (PKU)       |         REVEL |                   0.887 | `PKU_revel.png` |
| PAH (PKU)       | AlphaMissense |                  0.9182 | `PKU_Alpha.png` |

## 5) ACMG/AMP interpretation

The ACMG/AMP evidence codes and rationale were written in the Excel report under “ACMG/AMP”. In your report, each variant is classified as Pathogenic with supporting criteria (examples visible in the sheet include functional evidence such as PS3 and case enrichment such as PS4, depending on variant).

Important: this repository documents the **applied criteria in the report**; it is not an automated ACMG classifier.

## 6) Pipeline methodology

The shell pipeline implements a ClinVar-based annotation workflow using `tabix` and `bcftools`:

1. Index input VCF (bgzipped) with tabix
2. Subset to the three gene regions (GRCh38 coordinates)
3. Annotate against ClinVar VCF to add:

   * `INFO/CLNSIG`
   * `INFO/CLNDN`
4. Filter to retain Pathogenic or Likely_pathogenic variants

Gene intervals used in `pipeline.sh` (GRCh38):

* CFTR: `7:117465784-117605925`
* LDLR: `19:11089364-11133820`
* PAH:  `12:102838325-102917602`

## 7) Reproducibility

### Requirements

Install:

* `bcftools` (pipeline tested with bcftools 1.19 as recorded in the VCF header)
* `htslib/tabix`
* `bgzip` (usually shipped with htslib)

You also need a ClinVar VCF file (bgzipped + tabix-indexed). The script expects:

* `Data/clinvar.vcf.gz` (and `Data/clinvar.vcf.gz.tbi`)

### Recommended repository layout (to match the script paths)

```
.
├── Data/
│   ├── patient_variants.vcf.gz
│   ├── patient_variants.vcf.gz.tbi
│   ├── clinvar.vcf.gz
│   └── clinvar.vcf.gz.tbi
├── Clinical_Variant_Annotation_Report.xlsx
├── patient_variants.vcf
├── patient_final_filtered.vcf
├── pipeline.sh
└── *.png   (UCSC screenshots)
```

### pipeline

1. Compress + index the patient VCF (your repo also includes an uncompressed VCF; the script uses `.vcf.gz`):

```bash
mkdir -p Data
cp patient_variants.vcf Data/patient_variants.vcf
bgzip -c Data/patient_variants.vcf > Data/patient_variants.vcf.gz
tabix -p vcf Data/patient_variants.vcf.gz
```

2. Ensure ClinVar VCF is present and indexed:

```bash
# Example placeholders (you must provide the ClinVar VCF)
# bgzip -c clinvar.vcf > Data/clinvar.vcf.gz
# tabix -p vcf Data/clinvar.vcf.gz
```

3. Execute:

```bash
bash pipeline.sh
```

Expected outputs (as defined in `pipeline.sh`):

* `Data/patient_filtered_genes.vcf.gz`
* `Data/patient_annotated.vcf.gz`
* `Data/patient_final_filtered.vcf`

Your repository already contains an example final output: `patient_final_filtered.vcf`.

## 8) Main results

All three input variants were annotated as Pathogenic by ClinVar and retained after filtering:

| Locus (GRCh38) | REF>ALT | ClinVar fields added                                                            | Genotype |
| -------------- | ------- | ------------------------------------------------------------------------------- | -------- |
| 7:117587806    | G>A     | CLNSIG=Pathogenic; CLNDN includes CFTR-related disorder / Cystic fibrosis terms | 0/1      |
| 12:102840493   | G>A     | CLNSIG=Pathogenic; CLNDN includes PAH-related disorder / Phenylketonuria terms  | 0/1      |
| 19:11105587    | C>G     | CLNSIG=Pathogenic; CLNDN includes Familial hypercholesterolemia terms           | 0/1      |

Note on IDs: the raw VCF uses rsIDs, while the ClinVar-annotated output uses ClinVar-linked IDs (as produced by `bcftools annotate` against the ClinVar VCF).

## 9) Interpretation

* This repository demonstrates a realistic clinical annotation pattern: start from a patient-like VCF, annotate with ClinVar, filter by clinical significance, and then document supporting interpretation evidence in a report.
* AlphaMissense and REVEL are computational predictors; they support (but do not replace) clinical classification.
* ACMG/AMP classification in this project is documented manually in the Excel report based on reviewed evidence; it is not an automated ACMG engine.

## 10) Citation / data source acknowledgment

Primary resources used:

* ClinVar (variant classification and disease mapping)
* OMIM (phenotype definitions)
* UCSC Genome Browser (AlphaMissense and REVEL tracks)
* ACMG/AMP 2015 sequence variant interpretation framework

---

