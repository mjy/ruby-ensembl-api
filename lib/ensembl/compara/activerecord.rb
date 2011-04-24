#
#
# = ensembl/compara/activerecord.rb - ActiveRecord mappings to Compara 
#
# Copyright::   Copyright (C) 2011  STUB 
#                                      
# License::     The Ruby License
#
# @author STUB

# == What is it?
# The Ensembl module provides an API to the Ensembl databases
# stored at ensembldb.ensembl.org. This is the same information that is
# available from http://www.ensembl.org.
#
# The Ensembl::Core module mainly covers sequences and
# annotations.
# The Ensembl::Variation module covers variations (e.g. SNPs).
# The Ensembl::Compara module covers comparative mappings
# between species.
#
# == ActiveRecord
# See ensembl/core/activerecord.rb for notes on ActiveRecord basics. 

# The Ensembl::Compara module covers the tables
# found (and fully described) here:
# http://www.ensembl.org/info/docs/api/compara/compara_schema.html.
# 
# TODO: At present the following tables have not been stubbed:   
#       protein_tree_node / super_protein_tree_node
#       protein_tree_tag / super_protein_tree_tag
#       protein_tree_member / super_protein_tree_member
#       protein_tree_member_score
#       sitewise_aln
#       mapping_session
#       stable_id_history
#       protein_tree_stable_id
module Ensembl

  module Compara

    #=== General Tables

    # The Meta class contains configuration variables.
    class Meta < DBConnection
      set_primary_key 'meta_id'

      has_many :species

      validates_presence_of :meta_id, :species_id, :meta_key, :meta_value
    end

    # The NcbiTaxaNode class contains a description of the taxonomic relationships
    # between all the taxa used in this database.
    # It is usually read together with the ncbi_taxa_name table
    class NcbiTaxaNode < DBConnection
      set_primary_key nil

      belongs_to :taxon
      # TODO: what's the naming convention here? Is it just "parent"?
      belongs_to :parent, :foreign_key => :parent_id, :class_name => 'NcbiTaxaNode'

      has_many :genome_dbs, :foreign_key => :taxon_id
      has_many :members

      validates_presence_of :taxon_id, :parent_id, :rank, :genbank_hidden_flag, :left_index, :right_index, :root_id
    end

    # The NcbiTaxaName class contains descriptions the taxonimic nodes defined in the NcbiTaxaNode class.
    class NcbiTaxaName < DBConnection
      set_primary_key nil
      validates_presence_of :taxon_id
    end

    # The GenomeDb class contains information about the version of the genome assemblies used in this database.
    class GenomeDb < DBConnection
      set_primary_key 'genome_db_id'

      belongs_to :taxon, :class_name => 'NcbiTaxaNode', :foreign_key => :taxon_id 
      has_many :species_sets 
      has_many :members
      has_many :qgenome_dbs, :foreign_key => :qgenome_db_id, :class_name => 'PeptideAlignFeature' # TODO: relation named correctly?!
      has_many :hgenome_dbs, :foreign_key => :hgenome_db_id, :class_name => 'PeptideAlignFeature' # TODO: relation named correctly?!

      validates_presence_of :genome_db_id, :taxon_id, :name, :assembly, :genebuild 
    end

    # The SpeciesSet class contains groups or sets of species which are referenced in the MethodLinkSpeciesSet class.
    class SpeciesSet < DBConnection
      set_primary_key nil

      belongs_to :genome_db

      has_many :species_set_tags, :foreign_key => :tag
      has_many :method_link_species_sets

      validates_presence_of :species_set_id, :genome_db_id
    end

    # The SpeciesSetTag contains descriptive tags for the species_set_ids in a SpeciesSet class.
    class SpeciesSetTag < DBConnection
      set_primary_key 'species_set_id'

      belongs_to :tag, :foreign_key => :species_set_id, :class_name => 'SpeciesSet'

      validates_presence_of :species_set_id, :tag
    end

    # The MethodLink class contains the list of alignment methods used to find links (homologies) between entities in compara.
    class MethodLink < DBConnection
      set_primary_key 'method_link_id'

      has_many :method_link_species_sets

      validates_presence_of :method_link_id, :type, :class
    end

    # The MethodLinkSpeciesSet class This table contains information about the comparisons stored in the database. 
    # A given method_link_species_set_id exist for each comparison made and relates
    # a method_link.method_link_id with a set of species (species_set.species_set_id). 
    class MethodLinkSpeciesSet < DBConnection
      set_primary_key 'method_link_species_set_id'

      belongs_to :method_link
      belongs_to :species_set

      has_many :genomic_align_blocks
      has_many :genomic_aligns
      has_many :constrained_elements
      has_many :synteny_regions
      has_many :homologies
      has_many :families

      validates_presence_of :method_link_species_set_id, :species_set_id, :name, :source, :url
    end

    # The Analysis class is mainly used for production purposes.
    class Analysis < DBConnection
      set_primary_key 'analysis_id'

      has_many :analysis_descriptions
      has_many :peptide_align_features

      validates_presence_of :analysis_id, :created, :logic_name
    end

    # The AnalysisDescription class is included to comply with core Bio::EnsEMBL:DBSQL::AnalysisAdaptor requirements.
    class AnalysisDescription < DBConnection
      set_primary_key nil

      belongs_to :analysis

      validates_presence_of :analysis_id, :displayable
    end


    #=== Genomic Alignment Tables

    # The Dnafrag class defines the genomic sequences used in the comparative genomics analyisis. 
    # It is used by the genomic_align_block table to define aligned sequences. 
    # It is also used by the dnafrag_region table to define syntenic regions.  
    class Dnafrag < DBConnection
      set_primary_key 'dnafrag_id'

      belongs_to :genome_db # TODO: has_many

      has_many :genomic_aligns
      has_many :constrained_elements
      has_many :dnafrag_regions

      validates_presence_of :dnafrag_id, :length, :name, :genome_db_id, :is_reference
    end

    # The GenomicAlignBLock class defines genomic alignments. 
    # The software used to align the genomic blocks is refered as an external key to the method_link table.
    # Nevertheless, actual aligned sequences are defined in the GenomicAlign class.
    # Tree alignments (EPO alignments) are best accessed through the GenomicAlignTree class although the alignments are also indexed in this class.
    # This allows the user to also access the tree alignments as normal multiple alignments. 
    class GenomicAlignBlock < DBConnection
      set_primary_key 'genomic_align_block_id'

      belongs_to :method_link_species_set

      has_many :genomic_aligns
      has_many :conservation_scores

      validates_presence_of :genomic_align_block_id, :method_link_species_set_id
    end

    class GenomicAlign < DBConnection
      set_primary_key 'genomic_align_id'

      belongs_to :genomic_align_block
      belongs_to :method_link_species_set
      belongs_to :dnafrag

      has_many :genomic_align_groups

      validates_presence_of :genomic_align_id, :genomic_align_block_id, :method_link_species_set_id, :dnafrag_id, :dnafrag_start, :dnafrag_end, :dnafrag_strand, :level_id
    end

    class GenomicAlignTree < DBConnection
      set_primary_key 'node_id'

      belongs_to :parent, :class_name => 'GenomicAlignTree', :foreign_key => :parent_id # TODO: Is this true?  see http://www.ensembl.org/info/docs/api/compara/compara_schema.html#genomic_align_tree
      belongs_to :root, :class_name => 'GenomicAlignTree', :foreign_key => :root_id # TODO: Is this true?  see http://www.ensembl.org/info/docs/api/compara/compara_schema.html#genomic_align_tree
      belongs_to :left_node, :class_name => 'GenomicAlignTree', :foreign_key => :left_node_id # TODO: Is this true?  see http://www.ensembl.org/info/docs/api/compara/compara_schema.html#genomic_align_tree
      belongs_to :right_node, :class_name => 'GenomicAlignTree', :foreign_key => :right_node_id # TODO: Is this true?  see http://www.ensembl.org/info/docs/api/compara/compara_schema.html#genomic_align_tree

      has_many :genomic_align_groups

      validates_presence_of :node_id, :parent_id, :root_id, :left_index, :right_index, :left_node_id, :right_node_id, :distance_to_parent
    end

    class GenomicAlignGroup < DBConnection
      set_primary_key nil

      belongs_to :group, :class_name => 'GenomicAlignTree', :foreign_key => :node_id
      belongs_to :genomic_align

      validates_presence_of :group_id, :type, :genomic_align_id
    end

    class ConservationScore < DBConnection
      set_primary_key nil

      belongs_to :genomic_align_block

      validates_presence_of :genomic_align_block_id, :window_isze, :position
    end

    class ConstrainedElment < DBConnection
      set_primary_key 'constrained_element_id'

      belongs_to :dnfrag
      belongs_to :method_link_species_set_id

      validates_presence_of :constrained_element_id, :dnafrag_id, :dnafrag_start, :dnafrag_end, :method_link_species_set_id, :score
    end

    class SyntenyRegion < DBConnection
      set_primary_key 'synteny_region_id'

      belongs_to :method_link_species_set

      has_many :dna_frag_regions

      validates_presence_of :synteny_region_id, :method_link_species_set_id
    end

    class DnafragRegion < DBConnection
      set_primary_key nil

      belongs_to :synteny_region
      belongs_to :dnafrag

      validates_presence_of :synteny_region_id, :dnafrag_id, :dnafrag_start, :dnafrag_end, :dnafrag_strand
    end


    #=== Tables For Orthologues and Protein Clusters

    class Member < DBConnection
      set_primary_key 'member_id'

      belongs_to :ncbi_taxa_node
      belongs_to :genome_db
      belongs_to :sequence 
      belongs_to :gene_member, :foreign_key => :member_id, :class_name => 'Member'

      has_many :qmembers, :foreign_key => :qmember_id, :class_name => 'PeptideAlignFeature'
      has_many :hmembers, :foreign_key => :hmember_id, :class_name => 'PeptideAlignFeature'
      has_many :peptide_members, :foreign_key => :peptide_member_id, :class_name => 'HomologyMember'
      has_many :homology_members
      has_many :family_members

      validates_presence_of :member_id, :stable_id, :source_name, :taxon_id, :chr_strand
    end

    class Sequence < DBConnection
      set_primary_key 'sequence_id'

      has_many :members

      validates_presence_of :sequence_id, :length, :sequence
    end

    class PeptideAlignFeature < DBConnection
      set_primary_key 'peptide_align_feature_id'
  
      belongs_to :qmember, :foreign_key => :member_id, :class_name => 'Member'
      belongs_to :hmember, :foreign_key => :member_id, :class_name => 'Member'
      belongs_to :qgenome_db, :foreign_key => :qgenome_db_id, :class_name => 'GenomeDb'
      belongs_to :hgeonme_db, :foreign_key => :hgenome_db_id, :class_name => 'GenomeDb'
      belongs_to :analysis 

      has_many :homology_members

      validates_presence_of :peptide_align_feature_id, :qmember_id, :hmember_id, :qgenome_db_id, :hgenome_db_id, :analysis_id, :qstart, :qend, :hstart, :hend, :score
    end

    class Homology < DBConnection
      set_primary_key 'homology_id'

      belongs_to :method_link_species_set

      has_many :homology_member

      validates_presence_of :homology_id, :subtype, :ancestor_node_id, :tree_node_id
    end

    class HomologyMember < DBConnection
      set_primary_key nil 

      belongs_to :homology
      belongs_to :member
      belongs_to :peptide_member, :foreign_key => :peptide_member_id, :class_name => 'Member'
      belongs_to :peptide_align_feature

      validates_presence_of :homology_id, :member_id
    end

    class Family < DbConnection
      set_primary_key 'family_id'

      belongs_to :method_link_species_set
      # belongs_to :stable, :foreign_key :stable_id,  :class_name => "Family" # TODO: true?

      has_many :family_members

      validates_presence_of :family_id, :stable_id, :versoin, :method_link_specie_set_id
    end

    class FamilyMember < DBConnection
      set_primary_key nil

      belongs_to :family
      belongs_to :member

      validates_presence_of :family_id, :member_id
    end

    # TODO: Stopped at "protein_tree_node / super_protein_tree_node', these don't seem to be documented in the same manner, should the be included?
    # http://www.ensembl.org/info/docs/api/compara/compara_schema.html#protein_tree_node 

    # class ProteinTreeNode < DBConnection
    # # STUB
    # end
    
    # class ProteinTreeMember < DBConnection
    # # STUB
    # end

    # class ProteinTreeMemberScore < DBConnection
    # # STUB
    # end

    # class ProteinTreeTag < DBConnection
    # # STUB
    # end

    # class SitewiseAln < DBConnection
    # # STUB
    # end

    # class MappingSession < DBConnection
    # # STUB
    # end

    # class StableIdHistory < DBConnection
    # # STUB
    # end

    # class ProteinTreeStableId < DBConnection
    # # STUB
    # end

  end

end 

