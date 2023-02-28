require 'blockcypher'
require 'stringio'

class BitcoinWallet
  include Bitcoin::Builder
  FILE_PATH = 'data/private_key.txt'.freeze
  BLOCK_CYPHER = BlockCypher::Api.new(api_token: '5aa04682734c4911bed12a3f79407a2f', currency: BlockCypher::BTC,
                                      network: BlockCypher::TEST_NET_3).freeze
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
    BLOCK_CYPHER.address_final_balance(@key.addr).fdiv(100_000_000)
  end

  def transaction(addr, amount)
    address_info = BLOCK_CYPHER.address_details(@key.addr, unspent_only: true)
    prev_unconfirmed_txs = address_info['unconfirmed_txrefs'] || []
    prev_txs = address_info['txrefs'] || []
    all_prev_txs = prev_txs + prev_unconfirmed_txs

    all_prev_txs.map! do |tx|
      { hash: tx['tx_hash'], index: tx['tx_output_n'] }
    end

    commision = all_prev_txs.count * 148 + 2 * 34 + 10
    return 'not enough funds' if amount > balance * 100_000_000 + commision

    all_prev_txs.map! do |tx|
      raw = [BLOCK_CYPHER.blockchain_transaction(tx[:hash], includeHex: true)['hex']].pack('H*')

      { hash: Bitcoin::Protocol::Tx.new(raw), index: tx[:index] }
    end

    new_tx = build_tx do |t|
      all_prev_txs.each do |tx_info|
        t.input do |i|
          i.prev_out tx_info[:hash]
          i.prev_out_index tx_info[:index]
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
    BLOCK_CYPHER.push_hex(new_tx.to_payload.bth)
    'transaction has been sent'
  end
end
