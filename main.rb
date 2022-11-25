require 'bitcoin'
require_relative 'lib/bitcoin_wallet'
require 'blockcypher'
require_relative 'config/config'

abort 'too many arguments' if ARGV.count > 1

BitcoinWallet.save_key(ARGV[0]) unless File.exist?('data/private_key.txt')

bitcoin_wallet = BitcoinWallet.from_file

puts "your adress #{bitcoin_wallet.key.addr}"

input = nil
while input != 'exit'
  print 'enter exit/balance/transaction : '
  input = gets.chomp

  puts "balance: #{bitcoin_wallet.balance}" if input == 'balance'
  puts
end
