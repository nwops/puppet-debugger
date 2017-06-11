require_relative 'spec_helper'

describe PuppetDebugger::Hooks do
  before do
    @hooks = PuppetDebugger::Hooks.new
  end

  let(:output) do
    StringIO.new
  end

  let(:debugger) do
    PuppetDebugger::Cli.new(out_buffer: output)
  end
  
  describe "adding a new hook" do
    it 'should not execute hook while adding it' do
      run = false
      @hooks.add_hook(:test_hook, :my_name) { run = true }
      expect(run).to eq false
    end

    it 'should not allow adding of a hook with a duplicate name' do
      @hooks.add_hook(:test_hook, :my_name) {}

      expect { @hooks.add_hook(:test_hook, :my_name) {} }.to raise_error ArgumentError
    end

    it 'should create a new hook with a block' do
      @hooks.add_hook(:test_hook, :my_name) { }
      expect(@hooks.hook_count(:test_hook)).to eq 1
    end

    it 'should create a new hook with a callable' do
      @hooks.add_hook(:test_hook, :my_name, proc { })
      expect(@hooks.hook_count(:test_hook)).to eq 1
    end

    it 'should use block if given both block and callable' do
      run = false
      foo = false
      @hooks.add_hook(:test_hook, :my_name, proc { foo = true }) { run = true }
      expect(@hooks.hook_count(:test_hook)).to eq 1
      @hooks.exec_hook(:test_hook)
      expect(run).to eq true
      expect(foo).to eq false
    end

    it 'should raise if not given a block or any other object' do
      expect { @hooks.add_hook(:test_hook, :my_name) }.to raise_error ArgumentError
    end

    it 'should create multiple hooks for an event' do
      @hooks.add_hook(:test_hook, :my_name) {}
      @hooks.add_hook(:test_hook, :my_name2) {}
      expect(@hooks.hook_count(:test_hook)).to eq 2
    end

    it 'should return a count of 0 for an empty hook' do
      expect(@hooks.hook_count(:test_hook)).to eq 0
    end
  end

  describe "PuppetDebugger::Hooks#merge" do
    describe "merge!" do
      it 'should merge in the PuppetDebugger::Hooks' do
        h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
        h2 = PuppetDebugger::Hooks.new

        h2.merge!(h1)
        expect(h2.get_hook(:test_hook, :testing)).to eq h1.get_hook(:test_hook, :testing)
      end

      it 'should not share merged elements with original' do
        h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
        h2 = PuppetDebugger::Hooks.new

        h2.merge!(h1)
        h2.add_hook(:test_hook, :testing2) {}
        expect(h2.get_hook(:test_hook, :testing2)).not_to eq h1.get_hook(:test_hook, :testing2)
      end

      it 'should NOT overwrite hooks belonging to shared event in receiver' do
        h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
        callable = proc {}
        h2 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing2, callable)

        h2.merge!(h1)
        expect(h2.get_hook(:test_hook, :testing2)).to eq callable
      end

      it 'should overwrite identical hook in receiver' do
        callable1 = proc { :one }
        h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing, callable1)
        callable2 = proc { :two }
        h2 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing, callable2)

        h2.merge!(h1)
        expect(h2.get_hook(:test_hook, :testing)).to eq callable1
        expect(h2.hook_count(:test_hook)).to eq 1
      end

      it 'should preserve hook order' do
        name = ""
        h1 = PuppetDebugger::Hooks.new
        h1.add_hook(:test_hook, :testing3) { name << "h" }
        h1.add_hook(:test_hook, :testing4) { name << "n" }

        h2 = PuppetDebugger::Hooks.new
        h2.add_hook(:test_hook, :testing1) { name << "j" }
        h2.add_hook(:test_hook, :testing2) { name << "o" }

        h2.merge!(h1)
        h2.exec_hook(:test_hook)

        expect(name).to eq "john"
      end

      describe "merge" do
        it 'should return a fresh, independent instance' do
          h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
          h2 = PuppetDebugger::Hooks.new

          h3 = h2.merge(h1)
          expect(h3).not_to eq h1
          expect(h3).not_to eq h2
        end

        it 'should contain hooks from original instance' do
          h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
          h2 = PuppetDebugger::Hooks.new.add_hook(:test_hook2, :testing) {}

          h3 = h2.merge(h1)
          expect(h3.get_hook(:test_hook, :testing)).to eq h1.get_hook(:test_hook, :testing)
          expect(h3.get_hook(:test_hook2, :testing)).to eq h2.get_hook(:test_hook2, :testing)
        end

        it 'should not affect original instances when new hooks are added' do
          h1 = PuppetDebugger::Hooks.new.add_hook(:test_hook, :testing) {}
          h2 = PuppetDebugger::Hooks.new.add_hook(:test_hook2, :testing) {}

          h3 = h2.merge(h1)
          h3.add_hook(:test_hook3, :testing) {}

          expect(h1.get_hook(:test_hook3, :testing)).to eq nil
          expect(h2.get_hook(:test_hook3, :testing)).to eq nil
        end
      end

    end
  end

  describe "dupping a PuppetDebugger::Hooks instance" do
    it 'should share hooks with original' do
      @hooks.add_hook(:test_hook, :testing) do
        :none_such
      end

      hooks_dup = @hooks.dup
      expect(hooks_dup.get_hook(:test_hook, :testing)).to eq @hooks.get_hook(:test_hook, :testing)
    end

    it 'adding a new event to dupped instance should not affect original' do
      @hooks.add_hook(:test_hook, :testing) { :none_such }
      hooks_dup = @hooks.dup

      hooks_dup.add_hook(:other_test_hook, :testing) { :okay_man }

      expect(hooks_dup.get_hook(:other_test_hook, :testing)).not_to eq @hooks.get_hook(:other_test_hook, :testing)
    end

    it 'adding a new hook to dupped instance should not affect original' do
      @hooks.add_hook(:test_hook, :testing) { :none_such }
      hooks_dup = @hooks.dup

      hooks_dup.add_hook(:test_hook, :testing2) { :okay_man }

      expect(hooks_dup.get_hook(:test_hook, :testing2)).not_to eq @hooks.get_hook(:test_hook, :testing2)
    end

  end

  describe "getting hooks" do
    describe "get_hook" do
      it 'should return the correct requested hook' do
        run = false
        fun = false
        @hooks.add_hook(:test_hook, :my_name) { run = true }
        @hooks.add_hook(:test_hook, :my_name2) { fun = true }
        @hooks.get_hook(:test_hook, :my_name).call
        expect(run).to eq true
        expect(fun).to eq false
      end

      it 'should return nil if hook does not exist' do
        expect(@hooks.get_hook(:test_hook, :my_name)).to eq nil
      end
    end

    describe "get_hooks" do
      it 'should return a hash of hook names/hook functions for an event' do
        hook1 = proc { 1 }
        hook2 = proc { 2 }
        @hooks.add_hook(:test_hook, :my_name1, hook1)
        @hooks.add_hook(:test_hook, :my_name2, hook2)
        hash = @hooks.get_hooks(:test_hook)
        expect(hash.size).to eq 2
        expect(hash[:my_name1]).to eq hook1
        expect(hash[:my_name2]).to eq hook2
      end

      it 'should return an empty hash if no hooks defined' do
        expect(@hooks.get_hooks(:test_hook)).to eq({})
      end
    end
  end

  describe "clearing all hooks for an event" do
    it 'should clear all hooks' do
      @hooks.add_hook(:test_hook, :my_name) { }
      @hooks.add_hook(:test_hook, :my_name2) { }
      @hooks.add_hook(:test_hook, :my_name3) { }
      @hooks.clear_event_hooks(:test_hook)
      expect(@hooks.hook_count(:test_hook)).to eq 0
    end
  end

  describe "deleting a hook" do
    it 'should successfully delete a hook' do
      @hooks.add_hook(:test_hook, :my_name) {}
      @hooks.delete_hook(:test_hook, :my_name)
      expect(@hooks.hook_count(:test_hook)).to eq 0
    end

    it 'should return the deleted hook' do
      run = false
      @hooks.add_hook(:test_hook, :my_name) { run = true }
      @hooks.delete_hook(:test_hook, :my_name).call
      expect(run).to eq true
    end

    it 'should return nil if hook does not exist' do
      expect(@hooks.delete_hook(:test_hook, :my_name)).to eq nil
    end
  end

  describe "executing a hook" do
    it 'should execute block hook' do
      run = false
      @hooks.add_hook(:test_hook, :my_name) { run = true }
      @hooks.exec_hook(:test_hook)
      expect(run).to eq true
    end

    it 'should execute proc hook' do
      run = false
      @hooks.add_hook(:test_hook, :my_name, proc { run = true })
      @hooks.exec_hook(:test_hook)
      expect(run).to eq true
    end

    it 'should execute a general callable hook' do
      callable = Object.new.tap do |obj|
        obj.instance_variable_set(:@test_var, nil)
        class << obj
          attr_accessor :test_var
          def call() @test_var = true; end
        end
      end

      @hooks.add_hook(:test_hook, :my_name, callable)
      @hooks.exec_hook(:test_hook)
      expect(callable.test_var).to eq true
    end

    it 'should execute all hooks for an event if more than one is defined' do
      x = nil
      y = nil
      @hooks.add_hook(:test_hook, :my_name1) { y = true }
      @hooks.add_hook(:test_hook, :my_name2) { x = true }
      @hooks.exec_hook(:test_hook)
      expect(x).to eq true
      expect(y).to eq true
    end

    it 'should execute hooks in order' do
      array = []
      @hooks.add_hook(:test_hook, :my_name1) { array << 1 }
      @hooks.add_hook(:test_hook, :my_name2) { array << 2 }
      @hooks.add_hook(:test_hook, :my_name3) { array << 3 }
      @hooks.exec_hook(:test_hook)
      expect(array).to eq [1, 2, 3]
    end

    it 'return value of exec_hook should be that of last executed hook' do
      @hooks.add_hook(:test_hook, :my_name1) { 1 }
      @hooks.add_hook(:test_hook, :my_name2) { 2 }
      @hooks.add_hook(:test_hook, :my_name3) { 3 }
      expect(@hooks.exec_hook(:test_hook)).to eq 3
    end

    it 'should add exceptions to the errors array' do
      @hooks.add_hook(:test_hook, :foo1) { raise 'one' }
      @hooks.add_hook(:test_hook, :foo2) { raise 'two' }
      @hooks.add_hook(:test_hook, :foo3) { raise 'three' }
      @hooks.exec_hook(:test_hook)
      expect(@hooks.errors.map(&:message)).to eq ['one', 'two', 'three']
    end

    it 'should return the last exception raised as the return value' do
      @hooks.add_hook(:test_hook, :foo1) { raise 'one' }
      @hooks.add_hook(:test_hook, :foo2) { raise 'two' }
      @hooks.add_hook(:test_hook, :foo3) { raise 'three' }
      expect(@hooks.exec_hook(:test_hook)).to eq @hooks.errors.last
    end
  end

  describe "anonymous hooks" do
    it 'should allow adding of hook without a name' do
      @hooks.add_hook(:test_hook, nil) {}
      expect(@hooks.hook_count(:test_hook)).to eq 1
    end

    it 'should only allow one anonymous hook to exist' do
      @hooks.add_hook(:test_hook, nil) {  }
      @hooks.add_hook(:test_hook, nil) {  }
      expect(@hooks.hook_count(:test_hook)).to eq 1
    end

    it 'should execute most recently added anonymous hook' do
      x = nil
      y = nil
      @hooks.add_hook(:test_hook, nil) { y = 1 }
      @hooks.add_hook(:test_hook, nil) { x = 2 }
      @hooks.exec_hook(:test_hook)
      expect(y).to eq nil
      expect(x).to eq 2
    end
  end

end