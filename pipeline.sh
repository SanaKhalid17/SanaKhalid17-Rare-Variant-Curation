#!/bin/bash

# ==============================================================================
# Clinical Variant Interpretation Pipeline
# Author: Javeria Butt
# Purpose: Filter patient VCF for specific genes and annotate with ClinVar
# ==============================================================================

echo "Starting Clinical Variant Pipeline..."

# 1. Index the raw files (if needed)
tabix -p vcf Data/patient_variants.vcf.gz

# 2. Filter for gene regions (CFTR, LDLR, PAH) 
# Coordinates based on GRCh38
echo "Filtering gene regions..."
bcftools view -r 7:117465784-117605925,19:11089364-11133820,12:102838325-102917602 \
Data/patient_variants.vcf.gz -Oz -o Data/patient_filtered_genes.vcf.gz

# 3. Annotate with ClinVar
# This adds clinical significance (CLNSIG) and disease names (CLNDN)
echo "Annotating with ClinVar..."
bcftools annotate -a Data/clinvar.vcf.gz \
-c INFO/CLNSIG,INFO/CLNDN \
Data/patient_filtered_genes.vcf.gz -Oz -o Data/patient_annotated.vcf.gz

# 4. Extract final pathogenic/likely pathogenic variants for reporting
echo "Extracting high-impact variants..."
bcftools filter -i 'INFO/CLNSIG ~ "Pathogenic" || INFO/CLNSIG ~ "Likely_pathogenic"' \
Data/patient_annotated.vcf.gz -o Data/patient_final_filtered.vcf

echo "Pipeline complete. Final VCF located at: Data/patient_final_filtered.vcf"
