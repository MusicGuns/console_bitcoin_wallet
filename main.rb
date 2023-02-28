require 'bitcoin'
require_relative 'config/config'
require_relative 'lib/bitcoin_wallet'

abort 'too many arguments' if ARGV.count > 1

BitcoinWallet.save_key(ARGV[0]) if !File.exist?('data/private_key.txt') || ARGV[0]

bitcoin_wallet = BitcoinWallet.from_file

puts "your adress #{bitcoin_wallet.key.addr}"

input = nil
while input != 'exit'
  print 'enter exit/balance/transaction : '
  input = $stdin.gets.chomp

  puts "balance: #{bitcoin_wallet.balance}" if input == 'balance'
  next unless input == 'transaction'

  print 'address:'
  addr = $stdin.gets.chomp.to_s
  print 'amount(in satoshi):'
  amount = $stdin.gets.chomp.to_i
  puts bitcoin_wallet.transaction(addr, amount)
end
