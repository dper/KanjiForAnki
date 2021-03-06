#!/usr/bin/ruby
# coding: utf-8
#
# == NAME
# kanjiforanki.rb
#
# == USAGE
# ./kanjiforanki.rb
#
# == DESCRIPTION
# Takes a list of kanji as input and outputs a file that can be imported into
# Anki and used to study the given kanji.
# 
# == AUTHOR
#   Douglas Perkins - https://dperkins.org - https://microca.st/dper

require 'nokogiri'

# Extra functions for Arrays.
class Array
	# Returns the array minus the lead element, or [] if not possible.
	def rest
		case self.size
			when 0..1 then []
			else self[1..-1]
		end
	end
end

Script_dir = File.dirname(__FILE__)
require Script_dir + '/' + 'wordfreq'

# Fixes style quirks in Edict.
class Styler
	def initialize
		# For readability here, sort by lower case, then by initial
		# letter capitalized, then by all caps, then by phrases to
		# remove.
		@lookup_table = {
			'1/10bu' => '1/10 bu',
			'1/10sen' => '1/10 sen',
			'1/3lbs' => '1/3 lbs',
			'acknowledgement' => 'acknowledgment',
			'aeroplane' => 'airplane',
			'centre' => 'center',
			'colour' => 'color',
			'defence' => 'defense',
			'e.g. ' => 'e.g., ',
			'economising' => 'economizing',
			'electro-magnetic' => 'electromagnetic',
			'favourable' => 'favorable',
			'favourite' => 'favorite',
			'honour' => 'honor',
			'i.e. ' => 'i.e., ',
			'judgement' => 'judgment',
			'lakeshore' => 'lake shore',
			'metre' => 'meter',
			'neighbourhood' => 'neighborhood',
			'speciality' => 'specialty',
			'storeys' => 'stories',
			'theatre' => 'theater',
			'traveller' => 'traveler',
			'Ph.D' => 'PhD',
			'Philipines' => 'Philippines',
			'JUDGEMENT' => 'JUDGMENT',
			'(kokuji)' => 'kokuji',
			' (endeavour)' => '',
			' (labourer)' => '',
			' (theater, theater)' => '(theater)',
			' (theatre, theater)' => '(theater)',
		}
	end

	# Returns re-styled text.
	def fix_style text
		@lookup_table.keys.each do |key|
			text = text.sub(key, @lookup_table[key])
		end

		return text
	end
end

# Looks up words in Edict.
class Edict
	# Creates an Edict.  Parsing the edict file takes a long time,
	# so it is desirable to only make one of this.
	def initialize
		puts 'Parsing edict.txt ...'
		path = Script_dir + '/dictionaries/edict.txt'
		edict = IO.readlines path
		@lookup_table = {}
		
		edict.each do |line|
			# Lines with definitions start with the word, followed
			# by a blank line, followed by the definition.  If
			# there is more than one definition, the first one is
			# used.
			next unless line.include? " "
			word, blank, definition = line.partition " "
			next if @lookup_table.key? word
			@lookup_table[word] = definition
		end
	end

	# Looks up a word, returning its kana and definition.  Returns nil iff
	# the word is not in the dictionary.
	def define word
		# Definitions are stored in @lookup_table, which is indexed by
		# the words.  The definition starts with the reading in
		# parentheses, followed by one or more definitions, as well as
		# grammatical terms.  Only the first definition is used here.
		definition = @lookup_table[word]

		if not definition then return nil end

		kana = definition.partition('[')[2].partition(']')[0]

		meaning = definition.partition('/')[2]

		while meaning.start_with? '('
			meaning = meaning.partition(')')[2].lstrip
		end

		meaning = meaning.partition('/')[0]
		meaning = $styler.fix_style meaning
		return [kana, meaning]
	end
end

# An example word, written in kanji (plus kana), kana, and English.
class Example
	attr_accessor :word      # Word, using kanji and maybe kana.
	attr_accessor :kana      # Kana.
	attr_accessor :meaning   # English meaning.
	attr_accessor :frequency # Word frequency.

	# Creates an Example for a given word.
	def initialize (word, frequency)
		@word = word
		@frequency = Integer(frequency)
	end
	
	# Looks up the kana and English for the kanji word.
	# Returns true if the definition is found, and false otherwise.
	def lookup_definition
		definition = $edict.define @word
		if not definition then return false end
		@kana, meaning = definition
		meaning = $styler.fix_style meaning
		@meaning = meaning
		return true
	end
end

# A kanji character and all relevant details.
class Kanji
	attr_accessor :literal      # The character.
	attr_accessor :grade        # School grade level.
	attr_accessor :stroke_count # Stroke count.
	attr_accessor :meanings     # One or more meanings.
	attr_accessor :kunyomis     # Zero or more kunyomi readings.
	attr_accessor :onyomis	    # Zero or more onyomi readings.
	attr_accessor :examples     # Example list.

	Max_example_count = 3 # The maximum number of examples to store.
	Max_example_size = 50 # Max example width.

	# Look up examples of word use and record them.
	def lookup_examples
		@examples = []
		return unless $wordfreq.include? @literal
		$wordfreq.lookup(@literal).each do |pair|
			ex = Example.new(pair[0], pair[1])
		
			# Only keep examples that are in the dictionary.
			next unless ex.lookup_definition
			ex_size = (ex.word + ex.kana + ex.meaning).size
			next if ex_size > Max_example_size
			@examples << ex
			break if @examples.size == Max_example_count
		end
	end

	# Given a character node from nokogiri XML, creates a Kanji.
	def initialize (node)
		@literal = node.css('literal').text
		@grade = node.css('misc grade').text.to_i
		@stroke_count = node.css('misc stroke_count')[0].text

		rmgroup = node.css('reading_meaning rmgroup')

		# Parse the meanings.
		@meanings = []
		rmgroup.css('meaning').each do |meaning|
			if !meaning['m_lang']
				@meanings << ($styler.fix_style meaning.text)
			end
		end

		# Parse the readings.
		@onyomis = []
		@kunyomis = []
		rmgroup.css('reading').each do |reading|
			if reading['r_type'] == 'ja_on'
				@onyomis << reading.text
			elsif reading['r_type'] == 'ja_kun'
				@kunyomis << reading.text
			end
		end
		
		lookup_examples
	end
end

# Reader for kanjidic2.
class Kanjidic
	def initialize
		puts 'Parsing kanjidic2.xml ...'
		path = Script_dir + '/dictionaries/kanjidic2.xml'
		doc = Nokogiri::XML(open(path), nil, 'UTF-8')
		@characters = {}
		doc.xpath('kanjidic2/character').each do |node|
			character = node.css('literal').text
			@characters.store(character, node)
		end
		
		puts "Characters in kanjidic2: " + @characters.size.to_s + "."
	end

	# Returns a node for the specified characters.
	# If a character is not in the dictionary, it is skipped.
	def get_kanji characters
		kanjilist = []
		
		characters.each_char do |c|
			if @characters[c]
				kanjilist << Kanji.new(@characters[c])
			else
				puts "Character not found in kanjidic: " + c + "."
			end	
		end
		
		return kanjilist		
	end
end

# Reader for target kanji file.
class Targetkanji
	attr_accessor :kanjilist	# The target kanji.

	def lookup_characters characters
		@kanjilist = $kanjidic.get_kanji characters
		puts 'Found ' + @kanjilist.size.to_s + ' kanji in kanjidic.'
	end

	# Removes unwanted characters from the list.
	# This is a weak filter, but it catches the most obvious problems.
	def remove_unwanted_characters characters
		characters = characters.dup
		characters.gsub!(/[[:ascii:]]/, '')
		characters.gsub!(/[[:blank:]]/, '')
		characters.gsub!(/[[:cntrl:]]/, '')
		characters.gsub!(/[[:punct:]]/, '')
		characters.gsub!(/([\p{Hiragana}]+)/, '')
		characters.gsub!(/([\p{Katakana}]+)/, '')
		return characters	
	end

	def initialize
		puts 'Parsing targetkanji.txt ...'
		path = Script_dir + '/targetkanji.txt'
		characters = IO.read path
		characters = remove_unwanted_characters characters

		puts 'Target kanji count: ' + characters.size.to_s + '.'
		puts 'Target characters: ' + characters + '.'
		puts 'Looking up kanji ...'
		lookup_characters characters	
	end
end

# Makes the Anki deck for a given list of Kanji.
class Cardmaker
	# Makes the literal string.
	def make_literal literal
		s = literal
		return s
	end

	# Makes the stroke count string.
	def make_stroke_count stroke_count
		s = "✍" + stroke_count
		return s
	end

	# Makes the grade string.
	def make_grade grade
		if grade >= 1 and grade <= 6
			s = '小' + grade.to_s
		elsif grade == 8
			s = '中学'
		else
			s = ''
		end

		return s
	end

	# Makes the base meaning string.
	def make_base_meaning meaning
		s = meaning.upcase
		return s
	end

	# Makes the extra meaning string.
	def make_extra_meanings meanings
		if meanings.size == 0
			return ''
		end

		s = ''
		
		meanings.each do |meaning|
			s += meaning + ', '
		end

		s.chomp! ', '
		return s
	end

	# Makes the onyomi readings string.
	def make_onyomis readings
		if readings.size == 0
			return ''
		end

		s = ''

		readings.each do |reading|
			s += reading + '　'
		end

		s.chomp! '　'
		return s
	end

	# Makes the kunyomi readings string.
	def make_kunyomis readings
		if readings.size == 0
			return ''
		end

		s = ''

		readings.each do |reading|
			s += reading + '　'
		end

		s.chomp! '　'
		return s
	end

	# Makes the examples string.
	def make_examples examples
		s = ''

		examples.each do |example|
			word = example.word
			kana = example.kana
			meaning = example.meaning

			s += word + ' (' + kana + ') - ' + meaning
			s += '<br>'
		end

		s.chomp! '<br>'
		return s
	end

	# Makes the text for a card.
	def make_card kanji
		# Separates the front and back of the card.
		splitter = "\t"

		# The order of these lines is important.
		# If they are changed, care must be taken upon import.

		card = make_literal kanji.literal
		card += splitter
		card += make_stroke_count kanji.stroke_count
		card += splitter
		card += make_grade kanji.grade
		card += splitter
		card += make_base_meaning kanji.meanings[0]
		card += splitter
		card += make_extra_meanings kanji.meanings.rest
		card += splitter
		card += make_onyomis kanji.onyomis
		card += splitter
		card += make_kunyomis kanji.kunyomis
		card += splitter
		card += make_examples kanji.examples

		card += "\n"

		return card
	end

	# Makes the Anki deck and stores it as @deck.
	def make_deck kanjilist
		deck = ""

		kanjilist.each do |kanji|
			deck += make_card kanji
		end

		@deck = deck
	end

	def initialize kanjilist
		puts 'Making the deck ...'
		make_deck kanjilist
	end

	# Writes the contents of @deck to a text file.
	def write_deck
		file = 'anki.txt'
		path = Script_dir + '/' + file
		puts 'Writing the deck to ' + file + '...'

		open(path, 'w') do |f|
			f.puts @deck
		end		

		puts 'Done writing.'
	end
end

def make_deck
	# Read all of the files and data.
	$edict = Edict.new
	$wordfreq = Wordfreq.new
	$styler = Styler.new
	$kanjidic = Kanjidic.new
	$targetkanji = Targetkanji.new

	# Make the deck.
	$cardmaker = Cardmaker.new($targetkanji.kanjilist)
	$cardmaker.write_deck
end

make_deck
