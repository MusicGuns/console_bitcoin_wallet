require 'blockcypher'
require 'stringio'
require 'net/http'
require 'json'

class BitcoinWallet
  include Bitcoin::Builder
  FILE_PATH = 'data/private_key.txt'.freeze
  #BLOCK_CYPHER = BlockCypher::Api.new(api_token: '5aa04682734c4911bed12a3f79407a2f', currency: BlockCypher::BTC,
  #                                    network: BlockCypher::TEST_NET_3).freeze


  attr_reader :key

  def initialize(key)
    @key = key
  end

  def self.save_key(key)
    file_key = File.new(FILE_PATH, 'w')
    if key.nil?
      file_key.print(Bitcoin::Key.generate.to_base58)
    else
      begin
        file_key.print(Bitcoin::Key.from_base58(key).to_base58)
      rescue ArgumentError, RuntimeError => e
        File.delete(file_key)
        abort 'Invalid key'
      end
    end
    file_key.close
  end

  def self.from_file
    key = File.read(FILE_PATH)
    new(Bitcoin::Key.from_base58(key))
  end

  def balance
    JSON.parse(Net::HTTP.get(URI("https://blockstream.info/testnet/api/address/#{@key.addr}/utxo")))
      .reduce(0) { |sum, tx| sum += tx['value']  }
  end

  def transaction(addr, amount)
    utxo = JSON.parse(Net::HTTP.get(URI("https://blockstream.info/testnet/api/address/#{@key.addr}/utxo")))
    .map! do |tx|
      { hash: tx['txid'], index: tx['vout'] }
    end

    commision = utxo.count * 148 + 2 * 34 + 10
    return 'not enough funds' if amount > balance * 100_000_000 + commision

    utxo.map! do |tx|
      raw = Net::HTTP.get(URI("https://blockstream.info/testnet/api/tx/#{tx[:hash]}/raw"))

      { hash: Bitcoin::Protocol::Tx.new(raw), index: tx[:index] }
    end

    new_tx = build_tx do |t|
      utxo.each do |tx|
        t.input do |i|
          i.prev_out tx[:hash]
          i.prev_out_index tx[:index]
          i.signature_key @key
        end
      end

      t.output do |o|
        o.value amount
        o.script { |s| s.recipient addr }
      end

      t.output do |o|
        o.value balance * 100_000_000 - commision - amount
        o.script { |s| s.recipient @key.addr }
      end
    end
    p Net::HTTP.post(URI("https://blockstream.info/testnet/api/tx"), new_tx.to_payload.bth, nil)
    'transaction has been sent'
  end
end
