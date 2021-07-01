$HOSTNAME = ""
params.outdir = 'results'  


if (!params.genome){params.genome = ""} 
if (!params.cuffm){params.cuffm = ""} 
if (!params.outname_tot_intron){params.outname_tot_intron = ""} 
if (!params.outname_retained){params.outname_retained = ""} 
if (!params.introns_retained){params.introns_retained = ""} 
if (!params.outname_not_retained){params.outname_not_retained = ""} 
if (!params.outname_retained_len160){params.outname_retained_len160 = ""} 
if (!params.outname_not_retained_len160_1000){params.outname_not_retained_len160_1000 = ""} 
if (!params.outname_retained_dot){params.outname_retained_dot = ""} 
if (!params.outname_not_retained_dot){params.outname_not_retained_dot = ""} 

g_2_genome_g_11 = file(params.genome, type: 'any') 
g_2_genome_g_13 = file(params.genome, type: 'any') 
g_3_gtfFile_g_11 = file(params.cuffm, type: 'any') 
Channel.value(params.outname_tot_intron).set{g_5_name_g_11}
Channel.value(params.outname_retained).set{g_9_name_g_13}
g_12_gtfFile_g_13 = file(params.introns_retained, type: 'any') 
Channel.value(params.outname_not_retained).set{g_16_name_g_21}
Channel.value(params.outname_retained_len160).set{g_26_name_g_33}
Channel.value(params.outname_not_retained_len160_1000).set{g_31_name_g_30}
Channel.value(params.outname_retained_dot).set{g_35_name_g_34}
Channel.value(params.outname_not_retained_dot).set{g_38_name_g_37}


process ExtractEupVAIntron {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.fasta$/) "tot_introns/$filename"
	else if (filename =~ /.*.fastaPlus$/) "tot_introns_plus/$filename"
}

input:
 file eupVA_genome from g_2_genome_g_11
 file eupVA_cuffm from g_3_gtfFile_g_11
 val outputIT from g_5_name_g_11

output:
 file "*.fasta"  into g_11_fastaout
 file "*.fastaPlus"  into g_11_fastaPlus_g_21

"""
java -jar /data/experiment/programs/ExtractIntronsFromCufflink.jar -fa /data/experiment/input_files/$eupVA_genome -cu /data/experiment/input_files/$eupVA_cuffm -out $outputIT >> /data/experiment/process.log
"""
}


process ExtractIntronsFromAsta {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.fasta$/) "reteined/$filename"
	else if (filename =~ /.*.fastaPlus$/) "reteined_plus/$filename"
}

input:
 file genome from g_2_genome_g_13
 file introns_retained from g_12_gtfFile_g_13
 val name from g_9_name_g_13

output:
 file "*.fasta"  into g_13_fastaout
 file "*.fastaPlus"  into g_13_fastaPlus_g_21, g_13_fastaPlus_g_33

"""
java -jar /data/experiment/programs/ExtractIntronsFromAsta.jar -fa /data/experiment/input_files/$genome -tp /data/experiment/input_files/$introns_retained -out $name -l R >> /data/experiment/process.log
"""
}


process RemoveSeqLen {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.fasta$/) "reteined_len160/$filename"
}

input:
 file retained from g_13_fastaPlus_g_33
 val IR_removed_seq from g_26_name_g_33

output:
 file "*.fasta"  into g_33_fastaout_g_34

"""
 java -jar /data/experiment/programs/RemoveSeqLen.jar -f $retained -l 160 -out $IR_removed_seq >> /data/experiment/process.log
"""
}


process IR_CreateDotBraketNotation {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.dot$/) "reteined_dot_notation/$filename"
}

input:
 file fasta from g_33_fastaout_g_34
 val dotfileR from g_35_name_g_34

output:
 file "*.dot"  into g_34_outputFileDot

"""
RNAfold < $fasta > $dotfileR --noPS
"""
}


process RemoveContigFromFasta {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.fasta$/) "not_retained/$filename"
}

input:
 file outputITplus from g_11_fastaPlus_g_21
 file intronFasta from g_13_fastaPlus_g_21
 val notRetainedIntronFasta from g_16_name_g_21

output:
 file "*.fasta"  into g_21_fastaout_g_30

"""
java -jar /data/experiment/programs/RemoveContigFromFasta.jar -fa1 $outputITplus -fa2 $intronFasta -out $notRetainedIntronFasta -l N >> /data/experiment/process.log
"""
}


process GetFastaRandom {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.fasta$/) "not_retained_len160_1000/$filename"
}

input:
 file notretained from g_21_fastaout_g_30
 val outFastaNR1000 from g_31_name_g_30

output:
 file "*.fasta"  into g_30_fastaout_g_37

"""
 java -jar /data/experiment/programs/GetFastaRandom.jar -f $notretained -n 10000 -l 160 -out $outFastaNR1000 >> /data/experiment/process.log
"""
}


process INR_CreateDotBraketNotation {

publishDir params.outdir, overwrite: true, mode: 'copy',
	saveAs: {filename ->
	if (filename =~ /.*.dot$/) "not_retained_dot_notation/$filename"
}

input:
 file fasta from g_30_fastaout_g_37
 val dotfileR from g_38_name_g_37

output:
 file "*.dot"  into g_37_outputFileDot

"""
RNAfold < $fasta > $dotfileR --noPS
"""
}


workflow.onComplete {
println "##Pipeline execution summary##"
println "---------------------------"
println "##Completed at: $workflow.complete"
println "##Duration: ${workflow.duration}"
println "##Success: ${workflow.success ? 'OK' : 'failed' }"
println "##Exit status: ${workflow.exitStatus}"
}
