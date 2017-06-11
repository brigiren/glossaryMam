#!/usr/bin/env ruby

system "cls"
system "clear"

puts "---------------------------------"
puts "Website Generator"
puts "---------------------------------"


# Gem pour la gestion des templates
require 'erb'
# Gem pour la manipulation de structure
require 'ostruct'
# Gem pour la manipulation de fichier/rÈpertoire
require 'fileutils'
# Gem pour la manipulation des XML
require 'rexml/document'
include REXML

# Logs
#logg = File.open('logg.txt','w')

# Traitement des arguments
glossary_file = nil

ARGV.each{ |arg|
	case arg
		when /glossary=(.*)/
		glossary_file = arg.gsub(/(glossary=)/, "")
	end
}

# Vérification des d'arguments
if glossary_file == nil
	puts "Set a valid glossary data file path with glossary="
	exit
end

# Ouverture du fichier si existant
if File.exist?(glossary_file) == false
	puts "Invalid file Path"
	exit
end
file = File.open(glossary_file)
doc = Document.new(file)
root = doc.root

# Récupération des donées automatiques
time = Time.new
date = time.strftime("%Y-%m-%d")
user = ENV['USER']

# Création des structures recevant les infos
fileDataStruct = Struct.new( :pageName, :frWordClass, :frWord, :frExample, :enWordClass, :enWord, :enExample, :domain )

# On crée le fichier d'énumérateurs
ERB_glossary_page_template = ERB.new( File.read( './glossary_page_template.erb' ), nil, '-' )
ERB_glossary_ABC_template = ERB.new( File.read( './glossary_ABC_template.erb' ), nil, '-' )

# Création du dossier de sortie si non existant
if File.directory?('Output') == false
	FileUtils::mkdir_p 'Output'
end


#########################################################
#	Traitement des donées brutes						#
#-------------------------------------------------------#
#	Args : 	- filePath: Fichier	data (csv)  			#
#			- itemList: Tableau des donées             	#
#########################################################
def compute_glossary_data_file( filePath, itemList )
fileDataStruct = Struct.new( :pageName, :frWordClass, :frWord, :frExample, :enWordClass, :enWord, :enExample, :domain )

	# Ouverture du fichier si existant
	if File.exist?(filePath) == false
		puts "Invalid file Path"
		exit
	end
	file = File.open(filePath)

	puts "Computing " + filePath + "..."
	
	# Traitement du fichier
	file.each {|line|
	  if ((line.include? "mot anglais") == false )	# Exclusion de la première ligne
		splitted_Line = line.split("\t")
		# Affectation des variables
		frWord = splitted_Line[1].strip.squeeze(' ')
		enWord = splitted_Line[4].strip.squeeze(' ')
		domain = splitted_Line[6]
		frWordClass = splitted_Line[0]
		enWordClass = splitted_Line[3]
		# Mise en forme du mot
		pageName = splitted_Line[4].downcase.gsub(/(\/| |'|-)/, "_").gsub(/(\(|\))/, "").gsub(/(,|_$|^_)/, "")
		# Mise en forme des exemples
		puts splitted_Line[2]
		
		frExampleSrc = splitted_Line[2].capitalize
		enExampleSrc = splitted_Line[5].capitalize
		
		if( frExampleSrc.include? frWord )
			frExample = frExampleSrc.gsub(frWord, "<b><i>"+frWord.to_s+"</i></b>")
		else if ( frExampleSrc.include? frWord.capitalize )
			frExample = frExampleSrc.gsub(frWord.capitalize, "<b><i>"+frWord.to_s.capitalize+"</i></b>")
		else
			frExample = frExampleSrc
		end
		end
		
		if( enExampleSrc.include? enWord )
			enExample = enExampleSrc.gsub(enWord, "<b><i>"+enWord.to_s+"</i></b>")
		else if ( enExampleSrc.include? enWord.capitalize )
			enExample = enExampleSrc.gsub(enWord.capitalize, "<b><i>"+enWord.to_s.capitalize+"</i></b>")
		else
			enExample = enExampleSrc
		end
		end
		
		puts frExample
		itemList << fileDataStruct.new( pageName, frWordClass, frWord, frExample, enWordClass, enWord, enExample, domain )
	  end
	}
	
	puts "Computed " + itemList.count.to_s + " items"
end

#########################################################
#	Tri par ordre alphabetique EN						#
#-------------------------------------------------------#
#	Args : 	- itemList: Tableau des donées             	#
#########################################################
def sort_glossary_data_en( itemList )
fileDataStruct = Struct.new( :pageName, :frWordClass, :frWord, :frExample, :enWordClass, :enWord, :enExample, :domain )

return itemList.sort_by { |item| [item.enWord.downcase] }
	
	itemList.each {|item|
	#puts item.enWord
	}
end

#########################################################
#	Tri par ordre alphabetique FR						#
#-------------------------------------------------------#
#	Args : 	- itemList: Tableau des donées             	#
#########################################################
def sort_glossary_data_fr( itemList )
fileDataStruct = Struct.new( :pageName, :frWordClass, :frWord, :frExample, :enWordClass, :enWord, :enExample, :domain )

itemList = itemList.sort_by { |item| [item.frWord.downcase] }
	
	itemList.each {|item|
	#puts item.frWord
	}
end

#########################################################
#	Création des pages									#
#-------------------------------------------------------#
#	Args : 	- outputPath: Dossier de sortie  			#
#			- itemList: Tableau des donées             	#
#			- namespace: Namespace             			#
#########################################################
def create_glossary_pages_file( outputPath, itemList, namespace )
fileDataStruct = Struct.new( :pageName, :frWordClass, :frWord, :frExample, :enWordClass, :enWord, :enExample, :domain )

	puts "Creating pages in " + outputPath + "..."
	
	# Traitement du fichier
	itemList.each {|item|
	#puts item.pageName
	File.open( outputPath + "/" + item.pageName + ".html", 'w' ) { |objectFile| objectFile.write( ERB_glossary_page_template.result( namespace.instance_eval { binding } )  ) }
	}
	
	puts "Created " + itemList.count.to_s + " pages"
end

################################################################################################################################

###############################
#	Parcours du fichier CSV   #
###############################
itemList = Array.new
itemListSorted = Array.new

# Traitement du fichier data existant
compute_glossary_data_file( glossary_file, itemList )

# Tri des mots
itemListSortedEN = sort_glossary_data_en( itemList )
	itemListSortedEN.each {|item|
	#puts item.enWord
	}

# Creation des fichiers
namespaceFile = OpenStruct.new( glossary_file: glossary_file, itemList: itemList, date: date, user: user )
create_glossary_pages_file( "Output", itemList, namespaceFile )

File.open( "Output" + "/" + "ABC.html", 'w' ) { |objectFile| objectFile.write( ERB_glossary_ABC_template.result( namespaceFile.instance_eval { binding } )  ) }
