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

    uint256 GalangDatalength = 0;

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

    function createGalang(address _adr, string memory _nama, string memory _desc, uint256 _target, uint256 _deadline) public onlyOwner {
        require(_adr != address(0), "Address cannot be 0x0");
        require(_target > 0, "Target must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be greater than current time");

        GalangData[GalangDatalength] = Penggalang(_adr, _nama, _desc, _target, 0, _deadline, 0, 0);
        GalangDatalength++;
    }

    function depo(uint256 _idGalang) public payable {
        Penggalang memory galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(msg.value > 0, "Tidak ada Value");
        require(galangData.deadline > block.timestamp, "Galang dana sudah selesai");
        uint256 toBeDeposit = msg.value;
        if(toBeDeposit + galangData.terkumpul >= galangData.target) {
            uint256 toRefund = toBeDeposit + galangData.terkumpul - galangData.target;
            toBeDeposit = msg.value - toRefund;
            payable(msg.sender).transfer(toRefund);
        }

        GalangData[_idGalang].terkumpul += toBeDeposit;
        GalangData[_idGalang].totalDonatur++;
        donatur[_idGalang].push(IDonatur(msg.sender, toBeDeposit));
    }

    function withdraw(uint256 _idGalang) public {
        Penggalang memory galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.penggalang == msg.sender, "Bukan penggalang dana");
        require(galangData.deadline <= block.timestamp, "Penggalangan Dana belum selesai");
        require(galangData.status == 0, "Sudah di Withdraw");
        GalangData[_idGalang].status = 1;
        payable(msg.sender).transfer(galangData.terkumpul);
    }

    function FraudDonation(uint256 _idGalang) public onlyOwner {
        Penggalang memory galangData = GalangData[_idGalang];
        require(galangData.penggalang != address(0), "Penggalang tidak di temukan");
        require(galangData.status != 2, "Sudah ter refund");

        for ( uint i =0; i < galangData.totalDonatur;i++) {
            IDonatur memory Donatur = donatur[_idGalang][i];
            payable(Donatur.donatur).transfer(Donatur.value); 
        }

        GalangData[_idGalang].status = 2;
    }

    function getGalangData() public view returns (Penggalang[] memory) {
        if (GalangDatalength == 0) {
            return new Penggalang[](0);
        }
        
        Penggalang[] memory result = new Penggalang[](GalangDatalength);
        for (uint i = 0; i < GalangDatalength; i++) {
            result[i] = GalangData[i];
        }
        return result;
    }

}
