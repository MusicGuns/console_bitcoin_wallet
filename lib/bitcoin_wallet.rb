class BitcoinWallet
  FILE_PATH = 'data/private_key.txt'.freeze
  attr_reader :key

  def initialize(key)
    @key = key
    @block_cypher = BlockCypher::Api.new(api_token: '5aa04682734c4911bed12a3f79407a2f', currency: BlockCypher::BTC,
                                         network: BlockCypher::TEST_NET_3)
  end

  def self.save_key(key)
    file_key = File.new(FILE_PATH, 'a')
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
    key = File.new(FILE_PATH, 'r').readlines[0]
    new(Bitcoin::Key.from_base58(key))
  end

  def balance
    @block_cypher.address_final_balance(@key.addr).fdiv(100_000_000)
  end
end
