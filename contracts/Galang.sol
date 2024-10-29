// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Galang {

    address public owner;
    mapping(uint256 => Penggalang) public GalangData;

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

    mapping (uint256 => IDonatur[]) public donatur;

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

        GalangData[GalangDatalength] = Penggalang(msg.sender, _nama, _desc, _img, _target, 0, _deadline, 0, 0);
        GalangDatalength++;
    }

    function depo(uint256 _idGalang) public payable {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(msg.value > 0, "Tidak ada Value");
        require(galangData.deadline > block.timestamp, "Galang dana sudah selesai");
        require(galangData.target == galangData.terkumpul, "Target sudah tercapai");

        uint256 toBeDeposit = msg.value;
        if(toBeDeposit + galangData.terkumpul >= galangData.target) {
            uint256 toRefund = toBeDeposit + galangData.terkumpul - galangData.target;
            toBeDeposit -= toRefund;
            payable(msg.sender).transfer(toRefund);

            galangData.status = 1;
        }

        galangData.terkumpul += toBeDeposit;
        galangData.totalDonatur++;
        donatur[_idGalang].push(IDonatur(msg.sender, toBeDeposit));
    }

    function withdraw(uint256 _idGalang) public {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.penggalang == msg.sender, "Bukan penggalang dana");
        require(galangData.deadline <= block.timestamp, "Penggalangan Dana belum selesai");
        require(galangData.status == 0, "Sudah di Withdraw");

        galangData.status = 1;
        payable(msg.sender).transfer(galangData.terkumpul);
    }

    function FraudDonation(uint256 _idGalang) public onlyOwner {
        Penggalang storage galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.status != 2, "Sudah ter refund");

        IDonatur[] storage donaturList = donatur[_idGalang];
        for (uint i = 0; i < donaturList.length; i++) {
            payable(donaturList[i].donatur).transfer(donaturList[i].value); 
        }

        galangData.status = 2;
    }

    function getGalangData() public view returns (Penggalang[] memory) {
        Penggalang[] memory result = new Penggalang[](GalangDatalength);
        for (uint i = 0; i < GalangDatalength; i++) {
            result[i] = GalangData[i];
        }
        return result;
    }

    function getDonatur(uint256 _idGalang) public view returns (IDonatur[] memory) {
        return donatur[_idGalang];
    }
}