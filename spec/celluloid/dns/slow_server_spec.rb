#!/usr/bin/env ruby

# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'celluloid/dns'

module Celluloid::DNS::SlowServerSpec
	SERVER_PORTS = [[:udp, '127.0.0.1', 5330], [:tcp, '127.0.0.1', 5330]]
	IN = Resolv::DNS::Resource::IN
	
	class TestServer < Celluloid::DNS::Server
		def process(name, resource_class, transaction)
			@resolver ||= Celluloid::DNS::Resolver.new([[:udp, "8.8.8.8", 53], [:tcp, "8.8.8.8", 53]])
			
			sleep(2) if name.end_with?('.com')
			
			transaction.fail!(:NXDomain)
		end
	end
	
	describe "Celluloid::DNS Slow Server" do
		before(:all) do
			@server = TestServer.new(listen: SERVER_PORTS)
			@server.run
		end
		
		after(:all) do
			@server.terminate
		end
	
		it "get no answer after 2 seconds" do
			start_time = Time.now
		
			resolver = Celluloid::DNS::Resolver.new(SERVER_PORTS, :timeout => 10)
		
			response = resolver.query("apple.com", IN::A)
		
			expect(response.answer.length).to be == 0
		
			end_time = Time.now
		
			expect(end_time - start_time).to be_within(0.1).of(2.0)
		end
	
		it "times out after 1 second" do
			start_time = Time.now
		
			resolver = Celluloid::DNS::Resolver.new(SERVER_PORTS, :timeout => 0.5)
		
			response = resolver.query("apple.com", IN::A)
		
			expect(response).to be nil
		
			end_time = Time.now
		
			expect(end_time - start_time).to be_within(0.1).of(1.0)
		end
	
		it "gets no answer immediately" do
			start_time = Time.now
		
			resolver = Celluloid::DNS::Resolver.new(SERVER_PORTS, :timeout => 0.5)
		
			response = resolver.query("oriontransfer.org", IN::A)
		
			expect(response.answer.length).to be 0
		
			end_time = Time.now
		
			expect(end_time - start_time).to be_within(0.1).of(0.0)
		end
	end
end
