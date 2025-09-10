
import { Contract  } from "ethers";
export  async function queryRole(role:string,contract:Contract) : Promise<string[]>{
  const members: string[] = [];
  try {
    const count = await contract.getRoleMemberCount(role);
    const total = count.toNumber();

    for (let i = 0; i < total; i++) {
      const addr = await contract.getRoleMember(role, i);
      members.push(addr);
    }
  } catch (err) {
    console.error("Error in getRoleMembers:", err);
  }
  return members;
}
