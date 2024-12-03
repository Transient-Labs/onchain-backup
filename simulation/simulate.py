from hashlib import sha256
from math import ceil
from web3 import Web3, HTTPProvider
from hexbytes import HexBytes
import subprocess
from pathlib import Path
from eth_utils.currency import to_wei, from_wei

# start anvil
process = subprocess.Popen(["anvil", "--gas-price", "0", "--base-fee", "0"])

try:
    # simulate

    # get abi and bytecode
    r = subprocess.run(
        ["forge", "inspect", "OnchainBackup", "abi"], capture_output=True
    )
    abi = r.stdout.decode("utf-8")
    r = subprocess.run(["forge", "inspect", "OnchainBackup", "b"], capture_output=True)
    bytecode = HexBytes(r.stdout.decode("utf-8").strip())

    # create web3 stuff
    anvil_url = "http://127.0.0.1:8545"
    w3 = Web3(HTTPProvider(anvil_url))
    w3.eth.default_account = w3.eth.accounts[0]
    os_factory = w3.eth.contract(abi=abi, bytecode=bytecode)

    # deploy storage contract
    tx_hash = os_factory.constructor(
        w3.eth.default_account, [w3.eth.default_account, 1, ["video/mp4"]]
    ).transact()
    tx_reciept = w3.eth.wait_for_transaction_receipt(tx_hash)

    os_contract = w3.eth.contract(address=tx_reciept["contractAddress"], abi=abi)

    # load in video data
    fn = input(
        "Which size file do you want to test?\n0: 25KB\n1: 4MB\n2: 18MB\n3: 24MB\n4: 46MB\n\nEnter a number between 1 and 5: "
    )
    match fn:
        case "0":
            video_file = Path(__file__).parent / "25KB.mp3"
        case "1":
            video_file = Path(__file__).parent / "4MB.mp4"
        case "2":
            video_file = Path(__file__).parent / "18MB.mp4"
        case "3":
            video_file = Path(__file__).parent / "24MB.mp4"
        case "4":
            video_file = Path(__file__).parent / "46MB.mp4"
        case _:
            raise Exception("Invalid file choice selection")

    with open(video_file, "rb") as f:
        data = f.read()

    # get gas price
    gp = float(input("Enter in gas price for simulation (gwei): "))

    # chunk the bytes
    size = 100_000
    chunks = []
    num_chunks = ceil(len(data) / size)
    for i in range(num_chunks):
        chunks.append(HexBytes(data[i * size : i * size + size]))

    # upload each chunk
    print("\n\nStarting simulation...")
    gas_used = 0
    for i, chunk in enumerate(chunks):
        print(f"Chunk {i+1} of {num_chunks}")
        tx_hash = os_contract.functions.addAssetData(0, chunk).transact()

        tx_reciept = w3.eth.wait_for_transaction_receipt(tx_hash)
        gas_used += tx_reciept["gasUsed"]

    print(f"\n\nTotal gas used: {gas_used}")
    print(f"ETH spent at {gp} gwei: {gas_used * from_wei(to_wei(gp, "gwei"), "ether")}")
    print("\n\nVerifying hashes match from onchain simulation...")

    # get the data from the blockchain
    compiled_data = bytes()
    events = os_contract.events.AssetDataAdded().get_logs(from_block=0)

    for event in sorted(events, key=lambda e: e["blockNumber"]):
        compiled_data += event["args"]["data"]

    # compare hashes
    og_hash = sha256(data).hexdigest()
    ret_hash = sha256(compiled_data).hexdigest()

    assert og_hash == ret_hash
    print("✅ data hashes match!")
finally:
    # shut down anvil
    print("\n\nShutting down anvil...")
    process.terminate()  # send SIGTERM to the process
    try:
        process.wait(timeout=5)  # wait for it to exit gracefully
    except subprocess.TimeoutExpired:
        print("Anvil did not terminate, killing it...")
        process.kill()  # forcefully terminate the process
