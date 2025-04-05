// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Giao diện Oracle để lấy dữ liệu chuyến bay
interface FlightOracle {
    function getFlightStatus(string memory flightNumber, uint256 scheduledTime) external view returns (uint256 delayInMinutes);
}

contract FizzyInsurance {
    // Địa chỉ của Oracle cung cấp dữ liệu chuyến bay
    address public oracleAddress;
    
    // Chủ sở hữu hợp đồng (công ty bảo hiểm)
    address public owner;
    
    // Số tiền bồi thường cố định (tính bằng wei, đơn vị nhỏ nhất của ETH)
    uint256 public constant COMPENSATION_AMOUNT = 10 ether; // Bồi thường 10 ether
    
    // Thời gian trễ tối thiểu để kích hoạt bồi thường (2 tiếng = 120 phút)
    uint256 public constant MIN_DELAY_THRESHOLD = 120;
    
    // Cấu trúc lưu thông tin bảo hiểm của khách hàng
    struct Policy {
        address payable insured; // Địa chỉ ví của khách hàng
        string flightNumber;     // Số hiệu chuyến bay
        uint256 scheduledTime;   // Thời gian khởi hành dự kiến (timestamp)
        bool isClaimed;          // Trạng thái đã yêu cầu bồi thường chưa
    }
    
    // Lưu trữ danh sách các hợp đồng bảo hiểm
    mapping(uint256 => Policy) public policies;
    uint256 public policyCount;
    
    // Sự kiện để ghi lại khi mua bảo hiểm và bồi thường
    event PolicyPurchased(uint256 policyId, address insured, string flightNumber);
    event CompensationPaid(uint256 policyId, address insured, uint256 amount);
    
    // Chỉ chủ sở hữu mới có thể thực hiện một số hành động
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    // Khởi tạo hợp đồng với địa chỉ Oracle
    constructor(address _oracleAddress) {
        owner = msg.sender;
        oracleAddress = _oracleAddress;
    }
    
    // Hàm mua bảo hiểm
    function purchasePolicy(string memory _flightNumber, uint256 _scheduledTime) external payable {
        require(msg.value >= COMPENSATION_AMOUNT, "Insufficient payment");
        
        policyCount++;
        policies[policyCount] = Policy({
            insured: payable(msg.sender),
            flightNumber: _flightNumber,
            scheduledTime: _scheduledTime,
            isClaimed: false
        });
        
        emit PolicyPurchased(policyCount, msg.sender, _flightNumber);
    }
    
    // Hàm kiểm tra và bồi thường tự động
    function checkFlightDelay(uint256 _policyId) external {
        Policy storage policy = policies[_policyId];
        require(policy.insured != address(0), "Policy does not exist");
        require(!policy.isClaimed, "Compensation already claimed");
        
        // Gọi Oracle để lấy thông tin trễ chuyến bay
        FlightOracle oracle = FlightOracle(oracleAddress);
        uint256 delay = oracle.getFlightStatus(policy.flightNumber, policy.scheduledTime);
        
        // Nếu trễ quá ngưỡng, thực hiện bồi thường
        if (delay >= MIN_DELAY_THRESHOLD) {
            policy.isClaimed = true;
            policy.insured.transfer(COMPENSATION_AMOUNT);
            emit CompensationPaid(_policyId, policy.insured, COMPENSATION_AMOUNT);
        }
    }
    
    // Hàm cho phép chủ sở hữu rút tiền từ hợp đồng
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    // Hàm kiểm tra số dư hợp đồng
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}