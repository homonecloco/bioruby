#
# bio/alignment.rb - multiple alignment of sequences
#
#   Copyright (C) 2003 GOTO Naohisa <ngoto@gen-info.osaka-u.ac.jp>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
#
#  $Id: alignment.rb,v 1.1 2003/07/25 07:47:33 ng Exp $
#

require 'bio/sequence'

module Bio
  class Alignment

    GAP_REGEXP = /[^a-zA-Z]/
    GAP_CHAR = '-'
    MISSING_CHAR = '?'

    include Enumerable

    #
    ### class methods
    #

    def self.extract_seq(s)
      seq = nil
      if seq.is_a?(Bio::Sequence) then
	seq = s
      else
	for m in [ :seq, :naseq, :aaseq ]
	  begin
	    seq = s.send(m)
	  rescue NameError, ArgumentError
	    seq = nil
	  end
	  break if seq
	end
	seq = s unless seq
      end
      seq
    end

    def extract_seq(s)
      self.class.extract_seq(s)
    end
    private :extract_seq

    def self.extract_key(s)
      sn = nil
      for m in [ :definition, :entry_id ]
	begin
	  sn = s.send(m)
	rescue NameError, ArgumentError
	  sn = nil
	end
	break if sn
      end
      sn
    end

    def extract_key(s)
      self.class.extract_key(s)
    end
    private :extract_key

    #
    ### initializing methods
    #

    def self.new2(*arg)
      self.new(arg)
    end

    def initialize(seqs = [])
      @seqs = {}
      @keys = []
      if block_given? then
	seqs.each do |x|
	  s, key = yield x
	  self.store(key, s)
	end
      else
	if seqs.is_a?(self.class) then
	  seqs.each_pair do |k, s|
	    self.store(k, s)
	  end
	elsif seqs.respond_to?(:each_pair)
	  seqs.each_pair do |k, x|
	    s = extract_seq(x)
	    self.store(k, s)
	  end
	else
	  seqs.each do |x|
	    s = extract_seq(x)
	    k = extract_key(x)
	    self.store(k, s)
	  end
	end
      end
      true
    end

    #
    ### basic methods
    #
    attr_reader :keys

    def ==(x)
      #(original)
      if x.is_a?(self.class)
	self.to_hash == x.to_hash
      else
	false
      end
    end

    def to_hash
      #(Hash-like)
      @seqs
    end

    def __store__(key, seq)
      #(Hash-like)
      @keys << key
      @seqs[key] = seq
    end

    def store(key, seq)
      #(Hash-like) returns key instead of seq
      if @seqs.has_key?(key) then
	# don't allow same key
	# New key is discarded, while existing key is preserved.
	key = nil
      end
      unless key then
	unless defined?(@serial)
	  @serial = 0
	end
	@serial = @seqs.size if @seqs.size > @serial
	while @seqs.has_key?(@serial)
	  @serial += 1
	end
	key = @serial
      end
      self.__store__(key, seq)
      key
    end

    def unshift(key, seq)
      #(Array-like)
      self.store(key, seq)
      k = @keys.pop
      @keys.unshift(k)
      k
    end

    def shift
      #(Hash-like)
      k = @keys.shift
      if k then
	s = @seqs.delete(k)
	[ k, s ]
      else
	nil
      end
    end

    def order(n)
      #(original)
      @seqs[@keys[n]]
    end

    def delete(key)
      #(Hash-like)
      @keys.delete(key)
      @seqs.delete(key)
    end

    def values
      #(Hash-like)
      @keys.collect { |k| @seqs[k] }
    end

    def <<(s)
      #(Array-like)
      self.store(nil, s)
      self
    end

    def [](*arg)
      #(Hash-like)
      @seqs[*arg]
    end

    def size
      #(Hash&Array-like)
      @seqs.size
    end

    def has_key?(key)
      #(Hash-like)
      @seqs.has_key?(key)
    end

    def each
      #(Array-like)
      @keys.each do |k|
	yield @seqs[k]
      end
    end
    alias :each_seq :each

    def each_pair
      #(Hash-like)
      @keys.each do |k|
	yield k, @seqs[k]
      end
    end

    def collect!
      #(Array-like)
      @keys.each do |k|
	@seqs[k] = yield @seqs[k]
      end
    end
    #
    ### note that 'collect' and 'to_a' is defined in Enumerable
    #

    def seqclass
      #(original)
      (defined?(@seqclass) ? @seqclass : nil) or
	(@seqs[@keys[0]] ? @seqs[@keys[0]].class : String)
    end
    attr_writer :seqclass

    #
    ### methods for special characters
    #
    def gap_char
      #(original)
      unless defined?(@gap_char)
	@gap_char = String.new(GAP_CHAR)
      end
      @gap_char
    end
    attr_writer :gap_char

    def gap_regexp
      #(original)
      unless defined?(@gap_regexp)
	@gap_regexp = Regexp.new(GAP_REGEXP)
      end
      @gap_regexp
    end
    attr_writer :gap_regexp

    def missing_char
      #(original)
      # used in consensus methods
      unless defined?(@missing_char)
	@missing_char = String.new(MISSING_CHAR)
      end
      @missing_char
    end
    attr_writer :missing_char

    #
    ### instance-variable-related methods
    #
    def dup
      #(Hash-like)
      na = self.class.new(self)
      if defined?(@seqclass)
	na.seqclass = @seqclass
      end
      if defined?(@gap_char)
	na.gap_char = @gap_char
      end
      if defined?(@gap_regexp)
	na.gap_regexp = @gap_regexp
      end
      if defined?(@missing_char)
	na.missing_char = @missing_char
      end
      na
    end

    #
    ### methods below should not access instance variables
    #
    def merge(*other)
      #(Hash-like)
      na = self.class.new(self)
      na.merge!(*other)
      na
    end

    def merge!(*other)
      #(Hash-like)
      if block_given? then
	other.each do |aln|
	  aln.each_pair do |k, s|
	    if self.has_key?(k) then
	      s = yield k, self[k], s
	      self.to_hash.store(k, s)
	    else
	      self.store(k, s)
	    end
	  end
	end
      else
	other.each do |aln|
	  aln.each_pair do |k, s|
	    self.delete(k) if self.has_key?(k)
	    self.store(k, s)
	  end
	end
      end
      self
    end

    def index(seq)
      #(Hash-like)
      k = nil
      self.each_pair do |k, s|
	if s.class == seq.class then
	  r = (s == seq)
	else
	  r = (s.to_s == seq.to_s)
	end
	break if r
      end
      k
    end

    def isolate(*arg)
      #(original)
      if arg.size == 0 then
	self.collect! do |s|
	  seqclass.new(s)
	end
      else
	arg.each do |k|
	  if self.has_key?(k) then
	    s = self.delete(key)
	    self.store(k, seqclass.new(s))
	  end
	end
      end
      self
    end

    def collect_align
      #(original)
      na = self.class.new
      self.each_pair do |k, s|
	na.store(k, yield(s))
      end
      na
    end

    def add_seq(seq, key = nil)
      #(BioPerl) AlignI::add_seq like method
      unless seq.is_a?(Bio::Sequence) then
	s =   extract_seq(seq)
	key = extract_key(seq) unless key
	seq = s
      end
      self.store(key, seq)
    end

    def remove_seq(seq)
      #(BioPerl) AlignI::remove_seq like method
      if k = self.index(seq) then
	self.delete(k)
      else
	nil
      end
    end

    def purge(*arg)
      #(BioPerl) AlignI::purge like method
      purged = self.class.new
      arg.each do |k|
	if self[k] then
	  purged.store(k, self.delete(k))
	end
      end
      purged
    end

    def select(*arg)
      #(original)
      na = self.class.new
      if block_given? then
	# 'arg' is ignored
	# nearly same action as Array#select(Enumerable#select)
	self.each_pair.each do |k, s|
	  na.store(k, s) if yield(s)
	end
      else
	# BioPerl's AlignI::select like function
	arg.each do |k|
	  if s = self[k] then
	    na.store(k, s)
	  end
	end
      end
      na
    end

    def slice(*arg)
      #(BioPerl) AlignI::slice like method
      self.collect_align do |s|
	s.subseq(*arg)
      end
    end
    alias :subseq :slice

    def window(*arg)
      #(original)
      a = []
      self.each do |s|
	w = s[*arg]
	w = seqclass.new('') unless w
	a << w
      end
      a
    end

    def seq_length
      #(original)
      maxlen = 0
      self.each do |s|
	x = s.length
	maxlen = x if x > maxlen
      end
      maxlen
    end

    def each_site
      #(original)
      (0...(self.seq_length)).each do |i|
	yield self.collect do |s|
	  c = s[i..i]
	  c = seqclass.new(gap_char) if c.to_s.empty?
	  c
	end
      end
    end

    def each_window(window_size, step = 1)
      #(original)
      return nil if window_size < 0
      if step >= 0 then
	i = nil
	0.step(self.seq_length - window_size, step) do |i|
	  yield self.window(i, window_size)
	end
	self.window((i+window_size)..-1)
      else
	i = self.seq_length - window_size
	while i >= 0
	  yield self.window(i, window_size)
	  i += step
	end
	self.window(0...(i-step))
      end
    end

    def consensus_string(threshold = 1, mchar = self.missing_char)
      #(BioPerl) AlignI::consensus_string
      # 0 <= threshold <= 1
      cseq = ''
      self.each_site do |a|
	h = Hash.new(0)
	a.each do |x|
	  h[x] += 1
	end
	total = a.size
	a2 = h.to_a.sort do |x,y|
	  z = (x[1] <=> y[1])
	  z = (a.index(x[0]) <=> a.index(y[0])) if z == 0
	  z
	end
	if total * threshold <= a2[0][1] then
	  cseq << a2[0][0]
	else
	  cseq << mchar
	end
      end
      cseq
    end
    alias :consensus :consensus_string

    def convert_match(match_char = '.')
      #(BioPerl) AlignI::match like method
      if self.size > 0 then
	len = self.seq_length
	firstseq = self.order(0)
	flag = true
	self.each do |s|
	  if flag then
	    flag = nil
	    next
	  end
	  (0...len).each do |i|
	    s[i..i] = match_char if s[i] and
	      firstseq[i] == s[i] and !(gap_regexp =~ firstseq[i..i])
	  end
	end
      end
      self
    end

    def convert_unmatch(match_char = '.')
      #(BioPerl) AlignI::unmatch like method
      if self.size > 0 then
	len = self.seq_length
	firstseq = self.order(0)
	flag = true
	self.each do |s|
	  if flag then
	    flag = nil
	    next
	  end
	  (0...len).each do |i|
	    if s[i..i] == match_char then
	      s[i..i] = (firstseq[i..i] or match_char)
	    end
	  end
	end
      end
      self
    end

    # it is taken from Bio/SimpleAlign.pm (BioPerl 1.0)
    ## it is taken from Clustalw documentation
    ## These are all the positively scoring groups that occur in the 
    ## Gonnet Pam250 matrix. The strong and weak groups are 
    ## defined as strong score >0.5 and weak score =<0.5 respectively.
    Strong_Conservation_Groups = %w(STA NEQK NHQK NDEQ QHRK MILV MILF
      HY FYW).collect { |x| x.split('').sort.join('') }
    Weak_Conservation_Groups = %w(CSA ATV SAG STNK STPA SGND SNDEQK
      NDEQHK NEQHRK FVLIM HFY).collect { |x| x.split('').sort.join('') }

    def match_line(hash = {})
      #(BioPerl) AlignI::match_line like method
      #
      # hash[:match_line_char]   ==> 100% equal
      # hash[:strong_match_char] ==> strong match
      # hash[:weak_match_char]   ==> weak match
      # hash[:mismatch_char]     ==> mismatch
      # hash[:type] ==> :na or :aa (or determined by sequence class)
      # strong_ and weak_match_char are used only in amino mode (:aa)
      #
      mlc = (hash[:match_line_char]   or '*')
      smc = (hash[:strong_match_char] or ':')
      wmc = (hash[:weak_match_char]   or '.')
      mmc = (hash[:mismatch_char]     or ' ')
      if hash[:type] == :aa
	amino = true
      elsif hash[:type] == :na
	amino = false
      elsif self.order(0).class.is_a?(Bio::Sequence::AA) then
	amino = true
      elsif self.find { |x| /[EFILPQ]/i =~ x } then
	amino = true
      else
	amino = nil
      end
      mstr = ''
      if amino then
	self.each_site do |a|
	  a2 = a.sort.uniq
	  a3 = a2.join('')
	  mstr <<
	    (if a2.size == 1 and !(gap_regexp =~ a3)
	       mlc
	     elsif gap_regexp =~ a3
	       mmc
	     elsif Strong_Conservation_Groups.find { |x| x.index(a3) }
	       smc
	     elsif Weak_Conservation_Groups.find { |x| x.index(a3) }
	       wmc
	     else
	       mmc
	     end)
	end
      else
	self.each_site do |a|
	  a2 = a.sort.uniq
	  mstr <<
	    (if a2.size == 1 and !(gap_regexp =~ a2.join('')) then
	       mlc
	     else
	       mmc
	     end)
	end
      end
      mstr
    end

    def normalize
      #(original)
      len = self.seq_length
      self.each do |s|
	s << (gap_char * (len - s.length)) if s.length < len
      end
      self
    end

    def rstrip!
      #(String-like)
      len = self.seq_length
      self.each_window(1,-1) do |a|
	b = a.sort.uniq.compact
	if b.find_all { |x| gap_regexp =~ x } == b then
	  len -= 1
	else
	  break
	end
      end
      self.each do |s|
	s[len..-1] = '' if s.length > len
      end
      self
    end

    def lstrip!
      #(String-like)
      len = 0
      self.each_window(1,1) do |a|
	b = a.sort.uniq.compact
	if b.find_all { |x| gap_regexp =~ x } == b then
	  len += 1
	else
	  break
	end
      end
      if len > 0 then
	self.each do |s|
	  s[0, len] = ''
	end
      end
      self
    end

    def strip!
      #(String-like)
      self.lstrip!
      self.rstrip!
      self
    end

    def rstrip
      #(String-like)
      na = self.dup
      na.isolate
      na.rstrip!
      na
    end

    def lstrip
      #(String-like)
      na = self.dup
      na.isolate
      na.lstrip!
      na
    end

    def strip
      #(String-like)
      na = self.dup
      na.isolate
      na.strip!
      na
    end

    def remove_gap!
      #(original)
      self.each do |s|
	s.gsub!(gap_regexp, '')
      end
      self
    end

    def remove_gap
      #(original)
      na = self.dup
      na.isolate
      na.remove_gap!
      na
    end

    def concatinate(aln)
      #(original)
      if aln.is_a?(self.class) then
	aln.each_pair do |k, s|
	  self[k] << s
	end
      else
	i = 0
	aln.each do |s|
	  self.order(i) << s
	end
      end
      self
    end

    # perform multiple alignment
    def do_align(factory)
      #(original)
      a0 = self.class.new
      (0...self.size).each { |i| a0.store(i, self.order(i)) }
      r = factory.query(a0)
      a1 = r.align
      a0.keys.each do |k|
	unless a1[k.to_s] then
	  raise 'alignment result is inconsistent with input data'
	end
      end
      a2 = self.class.new
      a0.keys.each do |k|
	a2.store(self.keys[k], a1[k.to_s])
      end
      a2
    end

    # format conversion
    def self.have_same_name?(array, len = 30)
      na30 = array.collect do |k|
	k.to_s.split(/[\x00\s]/)[0].to_s[0, len].gsub(/\:\;\,\(\)/, '_').to_s
      end
      #p na30
      na30idx = (0...(na30.size)).to_a
      na30idx.sort! do |x,y|
	na30[x] <=> na30[y]
      end
      #p na30idx
      y = nil
      dupidx = []
      na30idx.each do |x|
	if y and na30[y] == na30[x] then
	  dupidx << y
	  dupidx << x
	end
	y = x
      end
      if dupidx.size > 0 then
	dupidx.sort!
	dupidx.uniq!
	dupidx
      else
	false
      end
    end

    def have_same_name?(*arg)
      self.class.have_same_name?(*arg)
    end
    private :have_same_name?

    def self.avoid_same_name(array, len = 30)
      na = array.collect { |k| k.to_s.gsub(/[\r\n\x00]/, ' ') }
      if dupidx = have_same_name?(na, len)
	procs = [
	  Proc.new { |s, i|
	    s[0, len].to_s.gsub(/\s/, '_') + s[len..-1].to_s
	  },
	  # Proc.new { |s, i|
	  #   "#{i}_#{s}"
	  # },
	]
	procs.each do |pr|
	  dupidx.each do |i|
	    s = array[i]
	    na[i] = pr.call(s.to_s, i)
	  end
	  dupidx = have_same_name?(na, len)
	  break unless dupidx
	end
	if dupidx then
	  na.each_with_index do |s, i|
	    na[i] = "#{i}_#{s}"
	  end
	end
      end
      na
    end

    def avoid_same_name(*arg)
      self.class.avoid_same_name(*arg)
    end
    private :avoid_same_name

    def to_fasta_array(width = nil, flag_avoid_same_name = nil)
      #(original)
      if flag_avoid_same_name then
	na = avoid_same_name(self.keys, 30)
      else
	na = self.keys.collect { |k| k.to_s.gsub(/[\r\n\x00]/, ' ') }
      end
      a = self.collect do |s|
	">#{na.shift}\n" +
	  if width then
	    s.to_s.gsub(Regexp.new(".{1,#{width}}"), "\\0\n")
	  else
	    s.to_s + "\n"
	  end
      end
      a
    end

    def to_fastaformat_array(*arg)
      #(original)
      require 'bio/db/fasta'
      a = self.to_fasta_array(*arg)
      a.collect! do |x|
	Bio::FastaFormat.new(x)
      end
      a
    end

    def to_fasta(*arg)
      #(original)
      self.to_fasta_array(*arg).join('')
    end

    def to_clustal(mline = nil, options = {})
      #(original)
      aln = [ "CLUSTAL   (0.00) multiple sequence alignment\n\n" ]
      len = self.seq_length

      if !options.has_key?(:avoid_same_name) or options[:avoid_same_name]
	sn = avoid_same_name(self.keys)
      else
	sn = self.keys.collect { |x| x.to_s.gsub(/[\r\n\x00]/, ' ') }
      end
      if options[:replace_space]
	sn.collect! { |x| x.gsub(/\s/, '_') }
      end
      unless options[:not_escape]
	sn.collect! { |x| x.gsub(/[\:\;\,\(\)]/, '_') }
      end
      unless options[:not_split]
	sn.collect! { |x| x.split(/\s/)[0].to_s }
      end

      if sn.find { |x| x.length > 10 } then
	seqwidth = 50
	namewidth = 30
	sep = ' ' * 6
      else
	seqwidth = 60
	namewidth = 10
	sep = ' ' * 6
      end
      seqregexp = Regexp.new("(.{1,#{seqwidth}})")

      aseqs = self.collect { |s| s.gsub(gap_regexp, gap_char) }
      case options[:case].to_s
      when /lower/i
	aseqs.each { |s| s.downcase! }
      when /upper/i
	aseqs.each { |s| s.upcase! }
      end

      case options[:type].to_s
      when /protein/i
	mopt = { :type => :aa }
      when /dna/i
	mopt = { :type => :na }
      else
	mopt = {}
      end
      mline = self.match_line(mopt) unless mline

      aseqs << mline
      aseqs.collect! do |s|
	snx = sn.shift
	head = sprintf("%*s", -namewidth, snx.to_s)[0, namewidth] + sep
	s << (gap_char * (len - s.length))
	s.gsub!(seqregexp, "\\1\n")
	a = s.split(/^/)
	if options[:seqnos] and snx then
	  i = 0
	  a.each do |x|
	    x.chomp!
	    l = x.gsub(gap_regexp, '').length
	    i += l
	    x << " #{i}" if l > 0
	    x << "\n"
	  end
	end
	a.collect { |x| head + x }
      end
      lines = (len + seqwidth - 1) / seqwidth
      lines.times do
	aln << "\n"
	aseqs.each { |a| aln << a.shift }
      end
      aln.join('')
    end

    #
    ### gap-related position translation
    #
    module GAP
      def ungapped_pos(seq, pos, gap_regexp)
	p = seq[0..pos].gsub(gap_regexp, '').length
	p -= 1 if p > 0
	p
      end
      module_function :ungapped_pos

      def gapped_pos(seq, pos, gap_regexp)
	olen = seq.gsub(gap_regexp, '').length
	pos = olen if pos >= olen
	pos = olen + pos if pos < 0
	
	i = 0
	l = pos + 1
	while l > 0 and i < seq.length
	  x = seq[i, l].gsub(gap_regexp, '').length
	  i += l
	  l -= x
	end
	i -= 1 if i > 0
	i
      end
      module_function :gapped_pos
    end # module GAP

  end #class Alignment

end #module Bio

=begin

= Bio::Alignment

  Bio::Alignment

-- Bio::Alignment.new()

-- Bio::Alignment#add_seq(seq[, key])

 Adds another sequence 'seq' to the alignment.
 Note: This method does not align sequences.

 add_seq(seq) returns internal id.

-- Bio::Alignment#remove_seq(x)

 Removes a single sequence from an alignment.
 Returns the removed sequence (or nil if nothing removed).

-- Bio::Alignment#purge(x, ...)

 Removes sequences specified in the arguments.
 Returns a new alginment of the removed sequences.

= References

* Bio::Align::AlignI class of the BioPerl.
((<URL:http://docs.bioperl.org/releases/bioperl-1.2/Bio/Align/AlignI.html>))

* Bio::SimpleAlign class of the BioPerl.
((<URL:http://docs.bioperl.org/releases/bioperl-1.2/Bio/SimpleAlign.html>))

=end