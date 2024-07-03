#! /home/ykodama/.rbenv/shims/ruby
# -*- coding: utf-8 -*-

#
# Analysis 4 types を交換用に変換
# 2024-07-01 児玉
#

require 'rubygems'
require 'pp'
require 'pg'
require 'date'
require 'nokogiri'
require 'optparse'
require 'builder'

# Analysis Exchange XML 生成
def create_xml(analysis_h, analysis_type, db)

	# exchange XML
	analysis_xml = Builder::XmlMarkup.new(:indent=>4)
	instruction = '<?xml version="1.0" encoding="UTF-8"?>'

	accession = analysis_h["accession"]
		
	analysis_f = open("#{db}/exchange/#{analysis_type}/#{accession}.exchange.xml", "w")
	analysis_f.puts instruction
	
  analysis_f.puts analysis_xml.ANALYSIS_SET{|analysis_set|

		analysis_set.ANALYSIS("accession" => accession, "center_name" => analysis_h["center_name"], "alias" => db == "dra" ? accession : analysis_h["alias"]){|analysis_e|
			
			# identifiers
			analysis_e.IDENTIFIERS{|identifiers|
				if analysis_h["primary_id"]
					identifiers.PRIMARY_ID(analysis_h["primary_id"]) 
				else
					identifiers.PRIMARY_ID(accession)
				end
				
				identifiers.SUBMITTER_ID(analysis_h["submitter_id"], "namespace" => analysis_h["submitter_id_namespace"]) if analysis_h["submitter_id"]
			}
		
			# Title
			analysis_e.TITLE(analysis_h["title"])

			# Study ref
			refname_h = {}
			if analysis_h["study_ref_refname"] && !analysis_h["study_ref_refname"].empty?
				refname_h.store("refname", analysis_h["study_ref_refname"])
			end
				
			refname_h.store("accession", analysis_h["study_ref_accession"])
			
			if analysis_h["study_ref_accession"]
				analysis_e.STUDY_REF(refname_h){|study_ref|
					study_ref.IDENTIFIERS{|identifiers|
						identifiers.PRIMARY_ID(analysis_h["study_ref_primary_id"] ? analysis_h["study_ref_primary_id"] : analysis_h["study_ref_accession"])
						identifiers.SECONDARY_ID(analysis_h["study_ref_secondary_id"]) if analysis_h["study_ref_secondary_id"]

						if analysis_h["study_ref_external_id"]
							if analysis_h["study_ref_external_id_namespace"]
								identifiers.EXTERNAL_ID(analysis_h["study_ref_external_id"], "namespace" => analysis_h["study_ref_external_id_namespace"])
							else
								identifiers.EXTERNAL_ID(analysis_h["study_ref_external_id"])
							end
						end
					}
				}
			else
				analysis_e.STUDY_REF(refname_h)
			end
			
			# sample_ref
			unless analysis_h["sample_ref"].empty?
				for sample_ref_h in analysis_h["sample_ref"]
					analysis_e.SAMPLE_REF{|sample_ref|
						sample_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(sample_ref_h["primary"])
								if sample_ref_h["external"]
									if sample_ref_h["external_namespace"]
										identifiers.EXTERNAL_ID(sample_ref_h["external"], "namespace" => sample_ref_h["external_namespace"])
									else
										identifiers.EXTERNAL_ID(sample_ref_h["external"])
									end
								end				
							} # identifiers
						} # sample_ref
				end
			end # unless
			
			# experiment_ref
			unless analysis_h["experiment_ref"].empty?
				for experiment_ref_h in analysis_h["experiment_ref"]
					analysis_e.EXPERIMENT_REF{|experiment_ref|
						experiment_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(experiment_ref_h["primary"])
								if experiment_ref_h["external"]
									if experiment_ref_h["external_namespace"]
										identifiers.EXTERNAL_ID(experiment_ref_h["external"], "namespace" => experiment_ref_h["external_namespace"])
									else
										identifiers.EXTERNAL_ID(experiment_ref_h["external"])
									end
								end
							} # identifiers
						} # experiment_ref
				end
			end # unless
			
			# run_ref
			unless analysis_h["run_ref"].empty?
				for run_ref_h in analysis_h["run_ref"]
					analysis_e.RUN_REF{|run_ref|
						run_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(run_ref_h["primary"])
								if run_ref_h["external"]
									if run_ref_h["external_namespace"]
										identifiers.EXTERNAL_ID(run_ref_h["external"], "namespace" => run_ref_h["external_namespace"])
									else
										identifiers.EXTERNAL_ID(run_ref_h["external"])
									end
								end				
							} # identifiers
						} # run_ref
				end
			end # unless
			
			# analysis_ref
			unless analysis_h["analysis_ref"].empty?
				for analysis_ref_h in analysis_h["analysis_ref"]
					analysis_e.ANALYSIS_REF{|analysis_ref|
						analysis_ref.IDENTIFIERS{|identifiers|
							identifiers.PRIMARY_ID(analysis_ref_h["primary"])
								if analysis_ref_h["external"]
									if analysis_ref_h["external_namespace"]
										identifiers.EXTERNAL_ID(analysis_ref_h["external"], "namespace" => analysis_ref_h["external_namespace"])
									else
										identifiers.EXTERNAL_ID(analysis_ref_h["external"])
									end
								end				
							} # identifiers
						} # analysis_ref
				end
			end # unless
			
			# Description
			analysis_e.DESCRIPTION(analysis_h["description"])
		
			case analysis_type
			
			when "base-modification"
		
				analysis_e.ANALYSIS_TYPE{|analysis_type|
					analysis_type.BASE_MODIFICATION
				}
				
			when "genome-map"
				analysis_e.ANALYSIS_TYPE{|analysis_type|
				
					if analysis_h["gmap"]
						analysis_type.GENOME_MAP{|genome_map|
								for gmap_h in analysis_h["gmap"]
									genome_map.PROGRAM(gmap_h["gmap-program"]) if gmap_h["gmap-program"]
									genome_map.PLATFORM(gmap_h["gmap-platform"]) if gmap_h["gmap-platform"]
								end
							}
					else
						analysis_type.GENOME_MAP
					end
				
				}

			when "binned-metagenome"
		
				analysis_e.ANALYSIS_TYPE{|analysis_type|
					analysis_type.METAGENOME_ASSEMBLY{|metagenome_assembly|
						metagenome_assembly.NAME(analysis_h["as-name"]) if analysis_h["as-name"]
						metagenome_assembly.TYPE(analysis_h["as-type"]) if analysis_h["as-type"]
						metagenome_assembly.PARTIAL(analysis_h["as-partial"]) if analysis_h["as-partial"]
						metagenome_assembly.COVERAGE(analysis_h["as-coverage"]) if analysis_h["as-coverage"]
						metagenome_assembly.PROGRAM(analysis_h["as-program"]) if analysis_h["as-program"]
						metagenome_assembly.PLATFORM(analysis_h["as-platform"]) if analysis_h["as-platform"]
						metagenome_assembly.MIN_GAP_LENGTH(analysis_h["as-min-gap-length"]) if analysis_h["as-min-gap-length"]
						metagenome_assembly.MOL_TYPE(analysis_h["as-mol-type"]) if analysis_h["as-mol-type"]
						metagenome_assembly.TPA(analysis_h["as-tpa"]) if analysis_h["as-tpa"]
						metagenome_assembly.AUTHORS(analysis_h["as-authors"]) if analysis_h["as-authors"]
						metagenome_assembly.ADDRESS(analysis_h["as-address"]) if analysis_h["as-address"]
					}
				}
				
			when "metagenome-assembly"
	
				analysis_e.ANALYSIS_TYPE{|analysis_type|
					case analysis_h["as-type"]
					when /binned/
						analysis_type.METAGENOME_ASSEMBLY{|metagenome_assembly| metagenome_assembly.TYPE("binned metagenome")}
					when /primary/
						analysis_type.METAGENOME_ASSEMBLY{|metagenome_assembly| metagenome_assembly.TYPE("primary metagenome")}
					when /mag/i
						analysis_type.METAGENOME_ASSEMBLY{|metagenome_assembly| metagenome_assembly.TYPE("Metagenome-Assembled Genome (MAG)")}
					else
						analysis_type.METAGENOME_ASSEMBLY
					end
				}

			when "genome-graph"
	
				analysis_e.ANALYSIS_TYPE{|analysis_type|
					analysis_type.ASSEMBLY_GRAPH{|assembly_graph|
						unless analysis_h["graph-standard"].empty?
							for graph_standard_h in analysis_h["graph-standard"]
								if graph_standard_h["as-standard-accession"]
									assembly_graph.ASSEMBLY{|assembly|
										assembly.STANDARD("accession" => graph_standard_h["as-standard-accession"])
									}
								elsif graph-standard_h["as-standard-refname"]
									assembly_graph.ASSEMBLY{|assembly|
										assembly.STANDARD("refname" => graph_standard_h["as-standard-refname"])
									}									
								end
							end
						end
					}
				}
				
			end # case analysis_type

			# FILES
			analysis_e.FILES{|files|
				for file_h in analysis_h["file"]
					files.FILE("filename" => file_h["filename"], "filetype" => file_h["filetype"], "checksum_method" => "MD5", "checksum" => file_h["checksum"])
				end
			} # FILES
			
			# PIPELINE			
			unless analysis_h["pipeline"].empty?
				# skip if only temporal one
				if !(analysis_h["pipeline"].size == 1 && (analysis_h["pipeline"][0]["program"].nil? || analysis_h["pipeline"][0]["program"].empty?))
					analysis_e.PROCESSING{|processing|
						processing.PIPELINE{|pipeline|
							for analysis_step in analysis_h["pipeline"]
								pipeline.PIPE_SECTION{|pipe_section|
									pipe_section.STEP_INDEX(analysis_step["step_index"])
									pipe_section.PREV_STEP_INDEX(analysis_step["prev_step_index"])
									pipe_section.PROGRAM(analysis_step["program"])
									pipe_section.VERSION(analysis_step["version"])
									pipe_section.NOTES(analysis_step["notes"]) unless analysis_step["notes"].empty?
								}
							end		
						} # piepline                   
					} # processing                  
				end # if
			end # unless		

			# links
			if !analysis_h["xref_link"].empty? || !analysis_h["url_link"].empty?
				analysis_e.ANALYSIS_LINKS{|analysis_links|
					analysis_links.ANALYSIS_LINK{|analysis_link|
						unless analysis_h["url_link"].empty?
							for url_h in analysis_h["url_link"]
								analysis_link.URL_LINK{|url_link|
									url_link.DB(url_h["db"]) if url_h["db"]
									url_link.ID(url_h["id"]) if url_h["id"]
								}
							end
						end
						unless analysis_h["xref_link"].empty?
							for xref_h in analysis_h["xref_link"]
								analysis_link.XREF_LINK{|xref_link|
									xref_link.DB(xref_h["db"]) if xref_h["db"]
									xref_link.ID(xref_h["id"]) if xref_h["id"]
								}
							end
						end
						} # link
				} # links
			end

			# attrs
			unless analysis_h["attrs"].empty?
				analysis_e.ANALYSIS_ATTRIBUTES{|analysis_attributes|
					for attr_h in analysis_h["attrs"]
						analysis_attributes.ANALYSIS_ATTRIBUTE{|analysis_attribute|
							analysis_attribute.TAG(attr_h["tag"]) if attr_h["tag"]
							analysis_attribute.VALUE(attr_h["value"]) if attr_h["value"]
							analysis_attribute.UNITS(attr_h["units"]) if attr_h["units"]
						}
					end
				} # analysis_attributes
			end
			
			} # analysis
				
		} # analysis set

end # def create_xml

# XML をパース
def parse_xml(path, analysis_type, db)
	
	## Base modification
	xml = Nokogiri::XML(open(path))

	xml.css("ANALYSIS").each{|analysis|
		
		analysis_h = {}

		if analysis.attribute("center_name") && analysis.attribute("center_name").value
			analysis_h.store("center_name", analysis.attribute("center_name").value)
		else
			analysis_h.store("center_name", "")
		end
		
		analysis_h.store("accession", analysis.attribute("accession").value)
		analysis_h.store("alias", analysis.attribute("alias").value)

		i = 0
		if analysis.css("IDENTIFIERS")
			analysis.css("IDENTIFIERS").each{|identifiers|
				if i == 0
					analysis_h.store("primary_id", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					if identifiers.at_css("SUBMITTER_ID")
						analysis_h.store("submitter_id", identifiers.at_css("SUBMITTER_ID").text) if identifiers.at_css("SUBMITTER_ID").text
						analysis_h.store("submitter_id_namespace", identifiers.at_css("SUBMITTER_ID").attribute("namespace").value) if identifiers.at_css("SUBMITTER_ID").attribute("namespace") && identifiers.at_css("SUBMITTER_ID").attribute("namespace").value
					end
				end
				i += 1
			}	
		end # if analysis.css("IDENTIFIERS")

		analysis_h.store("title", analysis.at_css("TITLE").text)
		analysis_h.store("description", analysis.at_css("DESCRIPTION").text) if analysis.at_css("DESCRIPTION") && analysis.at_css("DESCRIPTION").text

		if analysis.at_css("STUDY_REF")
			analysis.css("STUDY_REF").each{|study_ref|
				analysis_h.store("study_ref_refname", study_ref.attribute("refname").value) if study_ref.attribute("refname") && study_ref.attribute("refname").value
				analysis_h.store("study_ref_accession", study_ref.attribute("accession").value) if study_ref.attribute("accession") && study_ref.attribute("accession").value
				study_ref.css("IDENTIFIERS").each{|identifiers|
					analysis_h.store("study_ref_primary_id", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					analysis_h.store("study_ref_secondary_id", identifiers.at_css("SECONDARY_ID").text) if identifiers.at_css("SECONDARY_ID") && identifiers.at_css("SECONDARY_ID").text
					analysis_h.store("study_ref_external_id", identifiers.at_css("EXTERNAL_ID").text) if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").text
					analysis_h.store("study_ref_external_id_namespace", identifiers.at_css("EXTERNAL_ID").attribute("namespace").value) if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").attribute("namespace") && identifiers.at_css("EXTERNAL_ID").attribute("namespace").value
				}
			}
		end
		
		sample_ref_a = []
		experiment_ref_a = []
		run_ref_a = []
		analysis_ref_a = []

		# sample ref
		if analysis.at_css("SAMPLE_REF")
			analysis.css("SAMPLE_REF").each{|sample_ref|
				sample_ref.css("IDENTIFIERS").each{|identifiers|
					sample_ref_h = {}
					sample_ref_h.store("primary", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					sample_ref_h.store("secondary", identifiers.at_css("SECONDARY_ID").text) if identifiers.at_css("SECONDARY_ID") && identifiers.at_css("SECONDARY_ID").text
					if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").text
						sample_ref_h.store("external", identifiers.at_css("EXTERNAL_ID").text)
						sample_ref_h.store("external_namespace", identifiers.at_css("EXTERNAL_ID").attribute("namespace").value) if identifiers.at_css("EXTERNAL_ID").attribute("namespace") && identifiers.at_css("EXTERNAL_ID").attribute("namespace").value
					end
					sample_ref_a.push(sample_ref_h)
				}
			}
		end
		
		# experiment ref
		if analysis.at_css("EXPERIMENT_REF")
			analysis.css("EXPERIMENT_REF").each{|experiment_ref|
				experiment_ref.css("IDENTIFIERS").each{|identifiers|
					experiment_ref_h = {}
					experiment_ref_h.store("primary", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					experiment_ref_h.store("secondary", identifiers.at_css("SECONDARY_ID").text) if identifiers.at_css("SECONDARY_ID") && identifiers.at_css("SECONDARY_ID").text
					if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").text
						experiment_ref_h.store("external", identifiers.at_css("EXTERNAL_ID").text)
						experiment_ref_h.store("external_namespace", identifiers.at_css("EXTERNAL_ID").attribute("namespace").value) if identifiers.at_css("EXTERNAL_ID").attribute("namespace") && identifiers.at_css("EXTERNAL_ID").attribute("namespace").value
					end
					experiment_ref_a.push(experiment_ref_h)
				}
			}
		end
		
		# run ref
		if analysis.at_css("RUN_REF")
			analysis.css("RUN_REF").each{|run_ref|
				run_ref.css("IDENTIFIERS").each{|identifiers|
					run_ref_h = {}
					run_ref_h.store("primary", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					run_ref_h.store("secondary", identifiers.at_css("SECONDARY_ID").text) if identifiers.at_css("SECONDARY_ID") && identifiers.at_css("SECONDARY_ID").text
					if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").text
						run_ref_h.store("external", identifiers.at_css("EXTERNAL_ID").text)
						run_ref_h.store("external_namespace", identifiers.at_css("EXTERNAL_ID").attribute("namespace").value) if identifiers.at_css("EXTERNAL_ID").attribute("namespace") && identifiers.at_css("EXTERNAL_ID").attribute("namespace").value
					end
					run_ref_a.push(run_ref_h)
				}
			}
		end
		
		# analysis ref
		if analysis.at_css("ANALYSIS_REF")
			analysis.css("ANALYSIS_REF").each{|analysis_ref|
				analysis_ref.css("IDENTIFIERS").each{|identifiers|
					analysis_ref_h = {}
					analysis_ref_h.store("primary", identifiers.at_css("PRIMARY_ID").text) if identifiers.at_css("PRIMARY_ID") && identifiers.at_css("PRIMARY_ID").text
					analysis_ref_h.store("secondary", identifiers.at_css("SECONDARY_ID").text) if identifiers.at_css("SECONDARY_ID") && identifiers.at_css("SECONDARY_ID").text
					if identifiers.at_css("EXTERNAL_ID") && identifiers.at_css("EXTERNAL_ID").text
						analysis_ref_h.store("external", identifiers.at_css("EXTERNAL_ID").text)
						analysis_ref_h.store("external_namespace", identifiers.at_css("EXTERNAL_ID").attribute("namespace").value) if identifiers.at_css("EXTERNAL_ID").attribute("namespace") && identifiers.at_css("EXTERNAL_ID").attribute("namespace").value
					end
					analysis_ref_a.push(analysis_ref_h)
				}
			}
		end
		
		# analysis type
		if analysis.at_css("SEQUENCE_ASSEMBLY")
			analysis.css("SEQUENCE_ASSEMBLY").each{|sequence_assembly|
				analysis_h.store("as-name", sequence_assembly.at_css("NAME").text) if sequence_assembly.at_css("NAME") && sequence_assembly.at_css("NAME").text
				analysis_h.store("as-type", sequence_assembly.at_css("TYPE").text) if sequence_assembly.at_css("TYPE") && sequence_assembly.at_css("TYPE").text
				analysis_h.store("as-partial", sequence_assembly.at_css("PARTIAL").text) if sequence_assembly.at_css("PARTIAL") && sequence_assembly.at_css("PARTIAL").text
				analysis_h.store("as-coverage", sequence_assembly.at_css("COVERAGE").text) if sequence_assembly.at_css("COVERAGE") && sequence_assembly.at_css("COVERAGE").text
				analysis_h.store("as-program", sequence_assembly.at_css("PROGRAM").text) if sequence_assembly.at_css("PROGRAM") && sequence_assembly.at_css("PROGRAM").text
				analysis_h.store("as-platform", sequence_assembly.at_css("PLATFORM").text) if sequence_assembly.at_css("PLATFORM") && sequence_assembly.at_css("PLATFORM").text
				analysis_h.store("as-min-gap-length", sequence_assembly.at_css("MIN_GAP_LENGTH").text) if sequence_assembly.at_css("MIN_GAP_LENGTH") && sequence_assembly.at_css("MIN_GAP_LENGTH").text
				analysis_h.store("as-mol-type", sequence_assembly.at_css("MOL_TYPE").text) if sequence_assembly.at_css("MOL_TYPE") && sequence_assembly.at_css("MOL_TYPE").text
				analysis_h.store("as-tpa", sequence_assembly.at_css("TPA").text) if sequence_assembly.at_css("TPA") && sequence_assembly.at_css("TPA").text
				analysis_h.store("as-authors", sequence_assembly.at_css("AUTHORS").text) if sequence_assembly.at_css("AUTHORS") && sequence_assembly.at_css("AUTHORS").text
				analysis_h.store("as-address", sequence_assembly.at_css("ADDRESS").text) if sequence_assembly.at_css("ADDRESS") && sequence_assembly.at_css("ADDRESS").text
			}
		end

		# analysis type
		# CUSTOM 処理未実装
		as_standard_a = []
		as_custom_a = []
		if analysis.at_css("ASSEMBLY_GRAPH")
			analysis.css("ASSEMBLY_GRAPH").each{|assembly_graph|
				assembly_graph.css("ASSEMBLY").each{|assembly|
					as_standard_h = {}
					as_standard_h.store("as-standard-accession", assembly.at_css("STANDARD").attribute("accession").value) if assembly.at_css("STANDARD") && assembly.at_css("STANDARD").attribute("accession") && assembly.at_css("STANDARD").attribute("accession").value
					as_standard_h.store("as-standard-refname", assembly.at_css("STANDARD").attribute("refname").value) if assembly.at_css("STANDARD") && assembly.at_css("STANDARD").attribute("refname") && assembly.at_css("STANDARD").attribute("refname").value
					as_standard_a.push(as_standard_h)
				}
			}
			
			analysis_h.store("graph-standard", as_standard_a)
				
		end

		# genome map
		gmap_a = []
		if analysis.at_css("GENOME_MAP")
			analysis.css("GENOME_MAP").each{|genome_map|
					gmap_h = {}
					gmap_h.store("gmap-program", genome_map.at_css("PROGRAM").text) if genome_map.at_css("PROGRAM") && genome_map.at_css("PROGRAM").text
					gmap_h.store("gmap-platform", genome_map.at_css("PLATFORM").text) if genome_map.at_css("PLATFORM") && genome_map.at_css("PLATFORM").text
					gmap_a.push(gmap_h)
			}
			
			analysis_h.store("gmap", gmap_a)
				
		end

		# pipeline
		pipeline_a = []
		analysis.css("PIPE_SECTION").each{|pipeline|

			pipeline_h = {}	

			if pipeline.at_css("STEP_INDEX") && pipeline.at_css("STEP_INDEX").text
				pipeline_h.store("step_index", pipeline.at_css("STEP_INDEX").text)
			else
				pipeline_h.store("step_index", "")			
			end
			
			if pipeline.at_css("PREV_STEP_INDEX") && pipeline.at_css("PREV_STEP_INDEX").text
				pipeline_h.store("prev_step_index", pipeline.at_css("PREV_STEP_INDEX").text)
			else
				pipeline_h.store("prev_step_index", "")			
			end
			
			if pipeline.at_css("PROGRAM") && pipeline.at_css("PROGRAM").text
				pipeline_h.store("program", pipeline.at_css("PROGRAM").text)
			else
				pipeline_h.store("program", "")			
			end
			
			if pipeline.at_css("VERSION") && pipeline.at_css("VERSION").text
				pipeline_h.store("version", pipeline.at_css("VERSION").text)
			else
				pipeline_h.store("version", "")			
			end
			
			if pipeline.at_css("NOTES") && pipeline.at_css("NOTES").text
				pipeline_h.store("notes", pipeline.at_css("NOTES").text)
			else
				pipeline_h.store("notes", "")			
			end
			
			pipeline_a.push(pipeline_h)
		}
		
		analysis_h.store("pipeline", pipeline_a)

		# target
		analysis.css("TARGETS").each{|targets|
			targets.css("TARGET").each{|target|
				ref_acc = target.attribute("accession").value
				case ref_acc
				when /^SAM/ || /^[D|E|S]RS/
					sample_ref_a.push({"primary" => ref_acc})
				when /^[D|E|S]RX/
					experiment_ref_a.push({"primary" => ref_acc})
				when /^[D|E|S]RR/
					run_ref_a.push({"primary" => ref_acc})
				when /^[D|E|S]RZ/
					analysis_ref_a.push({"primary" => ref_acc})
				end				
			}
		}	

		analysis_h.store("sample_ref", sample_ref_a)
		analysis_h.store("experiment_ref", experiment_ref_a)
		analysis_h.store("run_ref", run_ref_a)
		analysis_h.store("analysis_ref", analysis_ref_a)
		
		# files
		file_a = []
		analysis.css("FILES").each{|files|
			files.css("FILE").each{|file|
				file_h = {}
				file_h.store("filename", file.attribute("filename").value)
				file_h.store("filetype", file.attribute("filetype").value)
				file_h.store("checksum", file.attribute("checksum").value)
				
				file_a.push(file_h)
			}
		}

		analysis_h.store("file", file_a)
		
		# links
		xlink_a = []
		ulink_a = []
		analysis.css("ANALYSIS_LINKS").each{|links|
			links.css("ANALYSIS_LINK").each{|link|
				link.css("XREF_LINK").each{|xref|
					xlink_h = {}
					xlink_h.store("id", xref.at_css("ID").text)
					xlink_h.store("db", xref.at_css("DB").text)					
					xlink_a.push(xlink_h)					
				}
				link.css("URL_LINK").each{|url|
					ulink_h = {}
					ulink_h.store("id", url.at_css("ID").text)
					ulink_h.store("db", url.at_css("DB").text)					
					ulink_a.push(ulink_h)
				}
			}
		}
		
		analysis_h.store("xref_link", xlink_a)
		analysis_h.store("url_link", ulink_a)

		# attributes
		attr_a = []
		analysis.css("ANALYSIS_ATTRIBUTES").each{|attrs|
			attrs.css("ANALYSIS_ATTRIBUTE").each{|attr|
				attr_h = {}
				attr_h.store("tag", attr.at_css("TAG").text) if attr.at_css("TAG") && attr.at_css("TAG").text
				attr_h.store("value", attr.at_css("VALUE").text) if attr.at_css("VALUE") && attr.at_css("VALUE").text
				attr_h.store("units", attr.at_css("UNITS").text) if attr.at_css("UNITS") && attr.at_css("UNITS").text					
				attr_a.push(attr_h)
				
				if attr_h["tag"] && attr_h["tag"] == "metagenome_assembly" 
					analysis_h.store("as-type", attr_h["value"])
				end
			}	
		}
		
		analysis_h.store("attrs", attr_a)
		create_xml(analysis_h, analysis_type, db)
			
	}
	
end

# XML or XMLs
#path = "ena/ena-base-modification/"
path = ARGV[0]

type = ""
case path
	
when /genome-map/
	type = "genome-map"
when /genome-graph/
	type = "genome-graph"
when /primary-metagenome/
	type = "primary-metagenome"
when /binned-metagenome/
	type = "binned-metagenome"
when /metagenome-assembly/
	type = "metagenome-assembly"
when /base-modification/
	type = "base-modification"	
end

db = ""
case path
when /dra\//
	db = "dra"
when /ena\//
	db = "ena"
when /sra\//
	db = "sra"
end

xml_a = []
if path !~ /\.xml$/
	for xml_path in Dir.glob("#{path}*xml")
		parse_xml(xml_path, type, db)
	end
else
	parse_xml(path, type, db)
end


