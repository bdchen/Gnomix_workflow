version 1.0

workflow run_gnomix_pretrained {
  input {
    Array[File] query_file
    Array[Int] chr_nr
    Boolean phase = true
    Array[File] pretrained_model
	String output_prefix
  }

  scatter(i in range(length(query_file))) {
    call gnomix_pretrained as gnomixs{
      input:
        query=query_file[i],
        chr=chr_nr[i],
        phase=phase,
        model=pretrained_model[i],
        prefix=output_prefix
    }
  }
    output {
      Array[File] vcf_array = select_all(flatten([gnomixs.vcf_file]))
	  Array[File] fb_array  = select_all(flatten([gnomixs.fb_file]))
	  Array[File] msp_file  = select_all(flatten([gnomixs.msp_file]))
    }

    meta {
        author: "Brian Chen"
        email: "brichen@unc.edu"
      }
  }


task gnomix_pretrained {
  input {

    # Gnomix pretrainted inputs 
    File query
    Int chr
    Boolean phase
    File model
	String prefix
	
    # Runtime specs
    Int gb_disk = 20
    Int gb_mem = 10
    Int n_cpu = 1
    Int preemptible = 0
  }
  
  command <<<
    cd /gnomix/
    
    python3 ./gnomix.py \
    ~{query} \
    /cromwell_root \
    ~${chr} \
    ~{phase} \
    ~{model}

    mv /cromwell_root/query_file_phased.vcf /cromwell_root/~{prefix}.chrom~{chr}.vcf
    
    mv /cromwell_root/query_results.fb /cromwell_root/~{prefix}.chrom~{chr}_results.fb

    mv /cromwell_root/query_results.msp /cromwell_root/~{prefix}.chrom~{chr}_results.msp

  >>>

    output {
      File vcf_file = "~{prefix}.chrom~{chr}.vcf"
      File fb_file  = "~{prefix}.chrom~{chr}_results.fb"
      File msp_file = "~{prefix}.chrom~{chr}_results.msp"
    }

  runtime {
         docker: "bdchen/run_gnomix:0.0.2"
          disks: "local-disk ${gb_disk} HDD"
         memory: "${gb_mem} GB"
            cpu: "${n_cpu}"
    preemptible: "${preemptible}"
  }

}
