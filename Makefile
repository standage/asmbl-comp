X=X
Y=Y
A=$(X)2$(Y)
B=$(Y)2$(X)

BIN=/usr/local/src/asmbl-comp
EVALUE=1e-20
BLASTTHREADS=1


all:			$(Y)_seq_reports


$(X).fasta.nin:		$(X).fasta
			makeblastdb -in $(X).fasta -dbtype nucl -parse_seqids > $(X)-makeblastdb.log

$(Y).fasta.nin:		$(Y).fasta
			makeblastdb -in $(Y).fasta -dbtype nucl -parse_seqids > $(Y)-makeblastdb.log

$(A).blastn:		$(X).fasta $(Y).fasta $(Y).fasta.nin
			blastn -query $(X).fasta -db $(Y).fasta -out $(A).blastn -evalue $(EVALUE) -num_threads $(BLASTTHREADS) -outfmt 6

$(B).blastn:		$(Y).fasta $(X).fasta $(X).fasta.nin
			blastn -query $(Y).fasta -db $(X).fasta -out $(B).blastn -evalue $(EVALUE) -num_threads $(BLASTTHREADS) -outfmt 6

$(A).edges:		$(A).blastn
			perl $(BIN)/blasttab-to-edges.pl $(X) $(Y) < $(A).blastn > $(A).edges

$(B).edges:		$(B).blastn
			perl $(BIN)/blasttab-to-edges.pl $(Y) $(X) < $(B).blastn > $(B).edges

seq_clust.txt:		$(A).edges $(B).edges
			perl $(BIN)/build-graph.pl --xlabel=$(X) --ylabel=$(Y) $(A).edges $(B).edges > seq_clust.txt 2> seq_clust.log

seq_clust_reports:	seq_clust.txt
			echo  "Breakdown of cluster types:"
			cut -f 1 seq_clust.txt | sort | uniq -c | perl -ne 'm/(\d+)\s+(\w+)/ and printf("  %10s: %d\n", $$2, $$1)'
			echo ""

$(X).queries:		$(A).edges
			cut -f 1 $(A).edges | sort | uniq > $(X).queries

$(Y).queries:		$(B).edges
			cut -f 1 $(B).edges | sort | uniq > $(Y).queries

$(X).subjects:		$(B).edges
			cut -f 2 $(B).edges | sort | uniq > $(X).subjects

$(Y).subjects:		$(A).edges
			cut -f 2 $(A).edges | sort | uniq > $(Y).subjects

$(X)_seq_reports:	$(X).queries $(X).subjects seq_clust_reports
			/bin/echo -n "Total $(X) sequences: "
			grep -c '^>' $(X).fasta
			/bin/echo -n "    queries only: "
			comm -23 $(X).queries $(X).subjects | wc -l
			/bin/echo -n "    subjects only: "
			comm -13 $(X).queries $(X).subjects | wc -l
			/bin/echo -n "    both queries and subjects: "
			comm -12 $(X).queries $(X).subjects | wc -l
			echo ""

$(Y)_seq_reports:	$(Y).queries $(Y).subjects $(X)_seq_reports
			/bin/echo -n "Total $(Y) sequences: "
			grep -c '^>' $(Y).fasta
			/bin/echo -n "    queries only: "
			comm -23 $(Y).queries $(Y).subjects | wc -l
			/bin/echo -n "    subjects only: "
			comm -13 $(Y).queries $(Y).subjects | wc -l
			/bin/echo -n "    both queries and subjects: "
			comm -12 $(Y).queries $(Y).subjects | wc -l
			echo ""

