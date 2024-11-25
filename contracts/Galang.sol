// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Galang {

    address public owner;
    mapping(bytes32 => Penggalang) public GalangData;
    bytes32[] private galangIds;

    /*
    status = 0; onprogress
    status = 1; withdrawn
    status = 2; fraud
    */
    struct Penggalang {
        address penggalang;
        string nama;
        string deskripsi;
        string image;
        uint256 target;
        uint256 terkumpul;
        uint256 deadline;
        uint256 totalDonatur;
        uint256 status;
    }

    // Events for transparancy
    event GalangCreated(address indexed penggalang, string nama, string deskripsi, string image, uint256 target, uint256 deadline);
    event Deposited(address indexed donatur, uint256 value);
    event Withdrawn(address indexed penggalang, uint256 value);
    event FraudedGalang(address indexed penggalang, uint256 value);
    mapping (bytes32 => IDonatur[]) public donatur;

    struct IDonatur {
        address donatur;
        uint256 value;
    }

    uint256 public GalangDatalength = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function createGalang(string calldata _nama, string calldata _desc, string calldata _img, uint256 _target, uint256 _deadline) public {
        require(_target > 0, "Target must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be greater than current time");

        bytes32 id = keccak256(abi.encodePacked(_nama, _desc, _img, _target, _deadline));
        require(GalangData[id].penggalang == address(0), "Galang dana sudah ada");
        GalangData[id] = Penggalang(msg.sender, _nama, _desc, _img, _target, 0, _deadline, 0, 0);
        galangIds.push(id);
        GalangDatalength++;
        
        emit GalangCreated(msg.sender, _nama, _desc, _img, _target, _deadline);
    }

    function depo(bytes32 _idGalang) public payable {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(msg.value > 0, "Tidak ada Value");
        require(galangData.deadline > block.timestamp, "Galang dana sudah selesai");

        uint256 toBeDeposit = msg.value;
        if(toBeDeposit + galangData.terkumpul >= galangData.target) {
            uint256 toRefund = toBeDeposit + galangData.terkumpul - galangData.target;
            toBeDeposit -= toRefund;
            payable(msg.sender).transfer(toRefund);
        }

        galangData.terkumpul += toBeDeposit;
        galangData.totalDonatur++;
        donatur[_idGalang].push(IDonatur(msg.sender, toBeDeposit));

        emit Deposited(msg.sender, toBeDeposit);
    }

    function withdraw(bytes32 _idGalang) public {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.penggalang == msg.sender, "Bukan penggalang dana");
        require(galangData.deadline <= block.timestamp, "Penggalangan Dana belum selesai");
        require(galangData.status == 0, "Sudah di Withdraw");

        galangData.status = 1;
        payable(msg.sender).transfer(galangData.terkumpul);

        emit Withdrawn(msg.sender, galangData.terkumpul);
    }

    function FraudDonation(bytes32 _idGalang) public onlyOwner {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.status != 2, "Sudah ter refund");

        IDonatur[] storage donaturList = donatur[_idGalang];
        for (uint i = 0; i < donaturList.length; i++) {
            payable(donaturList[i].donatur).transfer(donaturList[i].value); 
        }

        galangData.status = 2;

        emit FraudedGalang(msg.sender, galangData.terkumpul);
    }

    function getGalangData() public view returns (Penggalang[] memory) {
        Penggalang[] memory result = new Penggalang[](GalangDatalength);
        for (uint256 i = 0; i < GalangDatalength; i++) {
            result[i] = GalangData[galangIds[i]];
        }
        return result;
    }

    function getDonatur(bytes32 _idGalang) public view returns (IDonatur[] memory) {
        return donatur[_idGalang];
    }
}