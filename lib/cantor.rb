require File.expand_path(File.join(File.dirname(__FILE__), 'cantor/set'))

module Cantor
  module Sets
    U    = Universal = Set.new; Universal.name = :Universal
    Null = EmptySet  = Set.new; EmptySet.name  = :EmptySet
  end

  def self.set(*args, &block)
    if args.first && args.first.is_a?(Set)
      if args.count == 1 && !block
        args.first
      elsif args.count > 1  && !block
        Set.new(*args)
      else
        Set.new(*args, &block)
      end
    elsif args.empty? && !block
      EmptySet
    else
      Set.new(Sets::Universal, *args, &block)
    end
  end
end

include Cantor::Sets

module Kernel
  def defset(name, &block)
    block.call || raise("must define set with block")
    raise "must define set with 'from'" unless @set
    @set.name = name
    mod = self.to_s == 'main' ? Kernel : self
    mod.const_set(name, @set)
    @set
  end

  def from(*args, &block)
    @set = Cantor.set(*args, &block)
  end

  def where(method=nil, &block)
    if method
      block = Proc.new { |r| r.send(method) }  
    end
    Cantor::Query.new(&block)
  end

  def has(members)
    @set.members(members)
  end

  def us
    @set
  end
end
