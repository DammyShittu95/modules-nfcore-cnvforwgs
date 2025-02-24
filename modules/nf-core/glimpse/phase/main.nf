process GLIMPSE_PHASE {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::glimpse-bio=1.1.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/glimpse-bio:1.1.1--h2ce4488_2':
        'quay.io/biocontainers/glimpse-bio:1.1.1--hce55b13_1' }"

    input:
        tuple val(meta) , path(input), path(input_index), val(input_region), val(output_region), val(index_region), path(samples_file)
        tuple val(meta2), path(reference), path(reference_index)
        path(map)

    output:
        tuple val(meta), path("*.{vcf,bcf,vcf.gz,bcf.gz}"), emit: phased_variant
        path "versions.yml"                               , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def suffix = task.ext.suffix ?: "vcf.gz"
    def file_index = index_region ?: "0"

    def map_command = map ? "--map $map" : ""
    def samples_file_command = samples_file ? "--samples-file $samples_file":""
    def input_region_command = input_region ? "--input-region $input_region":""
    def output_region_command = output_region ? "--output-region $output_region":""

    """
    GLIMPSE_phase \\
        $args \\
        --input $input \\
        --reference $reference \\
        $map_command \\
        $samples_file_command \\
        $input_region_command \\
        $output_region_command \\
        --thread $task.cpus \\
        --output ${prefix}${file_index}.${suffix}

    cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            glimpse: "\$(GLIMPSE_phase --help | sed -nr '/Version/p' | grep -o -E '([0-9]+.){1,2}[0-9]')"
    END_VERSIONS
    """
}
