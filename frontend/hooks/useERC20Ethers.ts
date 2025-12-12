import { parseUnits } from 'ethers';
import { useEthersContract } from './useEthersContract';
import MockERC20ABI from '@/abi/MockERC20.json';

export function useERC20Ethers(tokenAddress: `0x${string}`, decimals: number = 18) {
  const { sendTransaction, callContract, isPending, txHash } = useEthersContract();

  const approve = async (spender: string, amount: string) => {
    const amountWei = parseUnits(amount, decimals);
    return sendTransaction(
      tokenAddress,
      MockERC20ABI,
      'approve',
      [spender, amountWei],
      { gasLimit: 100000 }
    );
  };

  const mintToSelf = async (amount: string) => {
    const amountWei = parseUnits(amount, decimals);
    return sendTransaction(
      tokenAddress,
      MockERC20ABI,
      'mintTo',
      [amountWei],
      { gasLimit: 100000 }
    );
  };

  const getBalance = async (address: string) => {
    const balance = await callContract(
      tokenAddress,
      MockERC20ABI,
      'balanceOf',
      [address]
    );
    return balance;
  };

  const getAllowance = async (owner: string, spender: string) => {
    const allowance = await callContract(
      tokenAddress,
      MockERC20ABI,
      'allowance',
      [owner, spender]
    );
    return allowance;
  };

  return {
    approve,
    mintToSelf,
    getBalance,
    getAllowance,
    isPending,
    txHash,
  };
}
