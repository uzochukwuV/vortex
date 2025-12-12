import { useState } from 'react';
import { BrowserProvider, Contract, parseUnits, JsonRpcProvider } from 'ethers';
import { useWalletClient } from 'wagmi';
import { toast } from 'sonner';

// Tenderly fork RPC for QIE Testnet
const QIE_TESTNET_RPC = 'https://virtual.mainnet.eu.rpc.tenderly.co/82c86106-662e-4d7f-a974-c311987358ff';

export function useEthersContract() {
  const { data: walletClient } = useWalletClient();
  const [isPending, setIsPending] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);

  const getProvider = async () => {
    if (!walletClient) throw new Error('No wallet connected');

    // @ts-ignore - wagmi wallet client to ethers provider
    return new BrowserProvider(walletClient);
  };

  const sendTransaction = async (
    contractAddress: string,
    abi: any[],
    functionName: string,
    args: any[],
    options: { gasLimit?: number; gasPrice?: string } = {}
  ) => {
    setIsPending(true);
    try {
      const provider = await getProvider();
      const signer = await provider.getSigner();
      const contract = new Contract(contractAddress, abi, signer);

      // Prepare transaction with legacy format
      const tx = await contract[functionName](...args, {
        gasLimit: options.gasLimit || 200000,
        gasPrice: options.gasPrice ? parseUnits(options.gasPrice, 'gwei') : parseUnits('2', 'gwei'),
        type: 0, // Legacy transaction
      });

      console.log('Transaction sent:', tx.hash);
      setTxHash(tx.hash);

      // Wait for confirmation
      const receipt = await tx.wait();
      console.log('Transaction confirmed:', receipt);

      setIsPending(false);
      return { hash: tx.hash, receipt };
    } catch (error: any) {
      console.error('Transaction error:', error);
      setIsPending(false);
      throw error;
    }
  };

  const callContract = async (
    contractAddress: string,
    abi: any[],
    functionName: string,
    args: any[]
  ) => {
    // Try with wallet provider first
    try {
      const provider = await getProvider();
      const contract = new Contract(contractAddress, abi, provider);
      const result = await contract[functionName](...args);
      return result;
    } catch (error: any) {
      console.warn('Wallet provider failed, trying fallback RPC:', error.message);

      // Try Tenderly fork as fallback
      try {
        const fallbackProvider = new JsonRpcProvider(QIE_TESTNET_RPC);
        const contract = new Contract(contractAddress, abi, fallbackProvider);
        const result = await contract[functionName](...args);
        console.log('Success with Tenderly fork RPC');
        return result;
      } catch (rpcError: any) {
        console.error('Tenderly fork RPC failed:', rpcError.message);
        throw new Error(`All RPC endpoints failed. Error: ${rpcError.message}`);
      }
    }
  };

  return {
    sendTransaction,
    callContract,
    isPending,
    txHash,
  };
}
